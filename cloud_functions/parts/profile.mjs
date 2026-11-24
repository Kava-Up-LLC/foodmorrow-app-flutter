// ---- this function
// Settings. Reads the seller back with no fields given; changes only the fields that are given.
export const handler = async (ctx) => {
  const body = input(ctx);
  const { seller_id: sellerId } = body;
  if (!validId(sellerId)) return BAD;
  if (!(await seller(ctx, sellerId))) return MISSING;

  if (body.business_name !== undefined) {
    const name = str(body.business_name, 40);
    if (!name) return BAD;
    await ctx.appambit.db('UPDATE sellers SET business_name = ? WHERE id = ?', [name, sellerId]);
  }
  if (body.week_start !== undefined) {
    if (!['mon', 'sun'].includes(body.week_start)) return BAD;
    await ctx.appambit.db('UPDATE sellers SET week_start = ? WHERE id = ?', [body.week_start, sellerId]);
  }
  const s = await seller(ctx, sellerId);
  return { ok: true, business_name: s.business_name, week_start: s.week_start };
};
