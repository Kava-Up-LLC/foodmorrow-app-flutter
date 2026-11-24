// ---- this function
// The only question that matters: what do I make tomorrow? Everything for that one day, added up across
// every order of the day — picked up or not, they all still had to be made (spec §2 rule 6) — plus the
// people picking up today. `today` and `tomorrow` come from the phone; the cloud never works them out.
export const handler = async (ctx) => {
  const { seller_id: sellerId, today, tomorrow } = input(ctx);
  if (!validId(sellerId) || !validDate(today) || !validDate(tomorrow)) return BAD;
  const s = await seller(ctx, sellerId);
  if (!s) return MISSING;

  // One row per product, largest first, ties A→Z. The name and photo are the menu's current ones when
  // the item is still on the menu, so renaming it doesn't split tomorrow's list in two.
  const items = (
    await q(
      ctx,
      `SELECT oi.product_id AS product_id,
              CASE WHEN p.id IS NULL THEN MAX(oi.product_name)  ELSE p.name  END AS name,
              CASE WHEN p.id IS NULL THEN MAX(oi.product_photo) ELSE p.photo END AS photo,
              SUM(oi.qty) AS qty,
              COUNT(DISTINCT oi.order_id) AS orders
         FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         LEFT JOIN products p ON p.id = oi.product_id AND p.seller_id = o.seller_id
        WHERE o.seller_id = ? AND o.pickup_date = ?
        GROUP BY oi.product_id
        ORDER BY qty DESC, lower(name), name`,
      [sellerId, tomorrow],
    )
  ).map((r) => ({
    name: r.name,
    photo: r.photo ?? null,
    qty: Number(r.qty),
    orders: Number(r.orders),
  }));

  const [counted] = await q(
    ctx,
    'SELECT COUNT(*) AS orders FROM orders WHERE seller_id = ? AND pickup_date = ?',
    [sellerId, tomorrow],
  );

  const pickups = await ordersWhere(ctx, sellerId, 'pickup_date = ?', [today]);

  return {
    ok: true,
    business_name: s.business_name,
    tomorrow: {
      date: tomorrow,
      things: items.reduce((sum, i) => sum + i.qty, 0),
      orders: Number(counted.orders),
      items,
    },
    today: {
      date: today,
      done: pickups.filter((o) => o.picked_up).length,
      total: pickups.length,
      pickups: pickups.map((o) => ({
        id: o.id,
        customer: o.customer,
        picked_up: o.picked_up,
        items: o.items.map((i) => ({ name: i.name, photo: i.photo, qty: i.qty })),
      })),
    },
  };
};
