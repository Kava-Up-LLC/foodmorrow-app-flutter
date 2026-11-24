// ---- this function
// The menu: what this seller sells. Every action answers with the whole active menu, so the app never
// has to guess what changed. `today` is the phone's date and only decides the "In N orders" count.
// Removing an item archives it: it leaves the menu and New order, and old orders keep its name and photo.
export const handler = async (ctx) => {
  const body = input(ctx);
  const { seller_id: sellerId, action, today, id } = body;
  if (!validId(sellerId) || !validDate(today)) return BAD;
  if (!['list', 'add', 'edit', 'remove'].includes(action)) return BAD;
  if (!(await seller(ctx, sellerId))) return MISSING;

  const menu = async () => ({ ok: true, products: await productList(ctx, sellerId, today) });
  if (action === 'list') return menu();

  if (action === 'remove') {
    if (!validId(id)) return BAD;
    const res = await ctx.appambit.db(
      'UPDATE products SET archived = 1 WHERE id = ? AND seller_id = ? AND archived = 0',
      [id, sellerId],
    );
    return written(res) > 0 ? menu() : MISSING;
  }

  // add and edit both need a name, and the name has to be free among this seller's active items.
  const name = str(body.name, 40);
  if (!name) return BAD;
  const photo = photoKey(body.photo);
  if (photo === false) return BAD;

  if (action === 'add') {
    const taken = await q(
      ctx,
      'SELECT id FROM products WHERE seller_id = ? AND archived = 0 AND lower(name) = lower(?)',
      [sellerId, name],
    );
    if (taken.length > 0) return DUPLICATE;
    await ctx.appambit.db(
      `INSERT INTO products (id, seller_id, name, photo, archived, created_at)
       VALUES (?, ?, ?, ?, 0, ${NOW})`,
      [randomUUID(), sellerId, name, photo],
    );
    return menu();
  }

  // edit
  if (!validId(id)) return BAD;
  const mine = await q(
    ctx,
    'SELECT id FROM products WHERE id = ? AND seller_id = ? AND archived = 0',
    [id, sellerId],
  );
  if (mine.length === 0) return MISSING;
  const clash = await q(
    ctx,
    `SELECT id FROM products
      WHERE seller_id = ? AND archived = 0 AND lower(name) = lower(?) AND id <> ?`,
    [sellerId, name, id],
  );
  if (clash.length > 0) return DUPLICATE;
  // No `photo` in the call means "leave the photo alone"; `photo: null` means "no photo".
  if ('photo' in body) {
    await ctx.appambit.db('UPDATE products SET name = ?, photo = ? WHERE id = ? AND seller_id = ?', [
      name, photo, id, sellerId,
    ]);
  } else {
    await ctx.appambit.db('UPDATE products SET name = ? WHERE id = ? AND seller_id = ?', [name, id, sellerId]);
  }
  return menu();
};
