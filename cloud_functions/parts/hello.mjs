// ---- this function
// Called on every app start. Creates the seller the first time this phone is seen, and hands back the
// two things the app needs before it can draw anything: the business name and the week start.
export const handler = async (ctx) => {
  const { seller_id: sellerId, platform } = input(ctx);
  if (!validId(sellerId) || !['ios', 'android'].includes(platform)) return BAD;

  await ctx.appambit.db(
    `INSERT INTO sellers (id, platform, created_at) VALUES (?, ?, ${NOW})
     ON CONFLICT(id) DO UPDATE SET platform = excluded.platform`,
    [sellerId, platform],
  );
  const s = await seller(ctx, sellerId);
  return { ok: true, business_name: s.business_name, week_start: s.week_start };
};
