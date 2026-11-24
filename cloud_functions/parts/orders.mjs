// ---- this function
// Everything about orders: the week strip, search, one order, saving, picked up and delete.
// An order and its items are always written together, so the app never sees half an order.
const ACTIONS = ['week', 'search', 'get', 'save', 'picked_up', 'delete'];

// The order payload from the phone, checked against spec §2 rule 3, or an error to return as is.
const draft = (body) => {
  const o = body.order;
  if (o == null || typeof o !== 'object') return BAD;

  const customer = str(o.customer, 40);
  if (!customer) return BAD;
  if (!validDate(o.pickup_date)) return BAD;

  let note = null;
  if (o.note != null && o.note !== '') {
    note = str(o.note, 140);
    if (!note) return BAD;
  }

  if (!Array.isArray(o.items) || o.items.length < 1 || o.items.length > 50) return BAD;
  const items = [];
  const seen = new Set();
  for (const it of o.items) {
    if (it == null || typeof it !== 'object') return BAD;
    const qty = typeof it.qty === 'number' ? it.qty : Number(it.qty);
    if (!validId(it.product_id) || !isInt(qty, 1, 999) || seen.has(it.product_id)) return BAD;
    seen.add(it.product_id);
    items.push({ product_id: it.product_id, qty });
  }

  if (o.id != null && !validId(o.id)) return BAD;
  return { id: o.id ?? null, customer, pickup_date: o.pickup_date, note, items };
};

export const handler = async (ctx) => {
  const body = input(ctx);
  const { seller_id: sellerId, action, id } = body;
  if (!validId(sellerId) || !ACTIONS.includes(action)) return BAD;
  if (!(await seller(ctx, sellerId))) return MISSING;

  if (action === 'week') {
    const { from, to } = body;
    // A strip is a week, but the range is whatever the phone asks for — capped so one call stays small.
    if (!validDate(from) || !validDate(to) || to < from || to > addDays(from, 30)) return BAD;
    const all = await ordersWhere(ctx, sellerId, 'pickup_date BETWEEN ? AND ?', [from, to]);
    const days = [];
    for (let day = from; day <= to; day = addDays(day, 1)) {
      days.push({ date: day, orders: all.filter((o) => o.pickup_date === day) });
    }
    return { ok: true, days };
  }

  if (action === 'search') {
    const needle = str(body.q, 40);
    if (!validDate(body.today) || !needle) return BAD;
    // The match is folded here, not in SQL: SQLite's lower() only folds ASCII, so "SOFÍA" would
    // miss "Sofía". Only the days from today on are read, so there is little to fold.
    const upcoming = await ordersWhere(ctx, sellerId, 'pickup_date >= ?', [body.today]);
    const want = needle.toLocaleLowerCase();
    return {
      ok: true,
      results: upcoming
        .filter((o) => o.customer.toLocaleLowerCase().includes(want))
        .map((o) => ({ date: o.pickup_date, order: o })),
    };
  }

  if (action === 'get') {
    if (!validId(id)) return BAD;
    const [order] = await ordersWhere(ctx, sellerId, 'id = ?', [id]);
    return order ? { ok: true, order } : MISSING;
  }

  if (action === 'picked_up') {
    if (!validId(id) || typeof body.picked_up !== 'boolean') return BAD;
    const res = await ctx.appambit.db(
      `UPDATE orders SET picked_up_at = ${body.picked_up ? NOW : 'NULL'}, updated_at = ${NOW}
        WHERE id = ? AND seller_id = ?`,
      [id, sellerId],
    );
    return written(res) > 0 ? { ok: true } : MISSING;
  }

  if (action === 'delete') {
    if (!validId(id)) return BAD;
    const mine = await q(ctx, 'SELECT id FROM orders WHERE id = ? AND seller_id = ?', [id, sellerId]);
    if (mine.length === 0) return MISSING;
    await ctx.appambit.batch(
      [
        { sql: 'DELETE FROM order_items WHERE order_id = ?', params: [id] },
        { sql: 'DELETE FROM orders WHERE id = ? AND seller_id = ?', params: [id, sellerId] },
      ],
      true,
    );
    return { ok: true };
  }

  // save — an insert, or an update when order.id is set. The items are replaced, never merged.
  const d = draft(body);
  if (d.error) return d;

  const marks = d.items.map(() => '?').join(',');
  const known = await q(
    ctx,
    `SELECT id, name, photo FROM products WHERE seller_id = ? AND id IN (${marks})`,
    [sellerId, ...d.items.map((it) => it.product_id)],
  );
  if (known.length !== d.items.length) return BAD; // an item that isn't on this seller's menu
  const byId = new Map(known.map((p) => [p.id, p]));

  const isNew = d.id == null;
  if (isNew) {
    // A new order is for today … +60 days (spec §2 rule 5). An edit may keep a date that has passed.
    if (body.today !== undefined) {
      if (!validDate(body.today)) return BAD;
      if (d.pickup_date < body.today || d.pickup_date > addDays(body.today, 60)) return BAD;
    }
  } else {
    const mine = await q(ctx, 'SELECT id FROM orders WHERE id = ? AND seller_id = ?', [d.id, sellerId]);
    if (mine.length === 0) return MISSING;
  }

  const orderId = isNew ? randomUUID() : d.id;
  const writes = isNew
    ? [
        {
          sql: `INSERT INTO orders (id, seller_id, customer, pickup_date, note, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ${NOW}, ${NOW})`,
          params: [orderId, sellerId, d.customer, d.pickup_date, d.note],
        },
      ]
    : [
        {
          sql: `UPDATE orders SET customer = ?, pickup_date = ?, note = ?, updated_at = ${NOW}
                 WHERE id = ? AND seller_id = ?`,
          params: [d.customer, d.pickup_date, d.note, orderId, sellerId],
        },
        { sql: 'DELETE FROM order_items WHERE order_id = ?', params: [orderId] },
      ];
  for (const it of d.items) {
    const p = byId.get(it.product_id);
    writes.push({
      sql: `INSERT INTO order_items (order_id, product_id, product_name, product_photo, qty)
            VALUES (?, ?, ?, ?, ?)`,
      params: [orderId, it.product_id, p.name, p.photo ?? null, it.qty],
    });
  }
  await ctx.appambit.batch(writes, true);
  return { ok: true, id: orderId };
};
