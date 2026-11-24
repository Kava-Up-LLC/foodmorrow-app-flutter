// The block every Foodmorrow function carries. Cloud Code deploys one file per function, so this is
// copied verbatim into hello.mjs, profile.mjs, products.mjs, orders.mjs and home.mjs by `make.mjs`.
// Edit it here and run `node cloud_functions/make.mjs` — never edit the copies by hand.
import { randomUUID } from 'node:crypto';

// db() answers { results: [{ columns, rows, ... }] } with positional rows. Turn them into objects.
const rows = (res) => {
  const r = res?.results?.[0];
  if (!r) return [];
  return (r.rows ?? []).map((row) =>
    Array.isArray(row) ? Object.fromEntries(r.columns.map((c, i) => [c, row[i]])) : row,
  );
};
const written = (res) => Number(res?.results?.[0]?.rows_written ?? 0);
const input = (ctx) => ctx.req?.body ?? ctx.req ?? ctx.event ?? {};
const q = async (ctx, sql, params = []) => rows(await ctx.appambit.db(sql, params));
// The database clock, never the phone. Milliseconds, so "oldest saved first" (spec §2 rule 7) is
// still right for two orders saved in the same second.
const NOW = "strftime('%Y-%m-%d %H:%M:%f','now')";
const BAD = { ok: false, error: 'BAD_INPUT' };
const MISSING = { ok: false, error: 'NOT_FOUND' };
const DUPLICATE = { ok: false, error: 'DUPLICATE' };

const validId = (v) => typeof v === 'string' && /^[A-Za-z0-9-]{8,64}$/.test(v);
// A 'YYYY-MM-DD' that is a real day (2026-02-30 is not one).
const validDate = (v) => {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
  const d = new Date(`${v}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
};
const addDays = (date, n) =>
  new Date(new Date(`${date}T00:00:00Z`).getTime() + n * 86400000).toISOString().slice(0, 10);
// A trimmed string of min..max characters, or null when the value isn't one.
const str = (v, max, min = 1) => {
  if (typeof v !== 'string') return null;
  const s = v.trim();
  return s.length >= min && s.length <= max ? s : null;
};
// A photo key from the app's library ('cookies'), null for no photo, false when it's neither.
const photoKey = (v) => {
  if (v == null || v === '') return null;
  return typeof v === 'string' && /^[a-z0-9_]{1,40}$/.test(v) ? v : false;
};
const isInt = (v, min, max) => Number.isInteger(v) && v >= min && v <= max;

// The seller's row, or null. Every function starts here: no seller, nothing to answer.
const seller = async (ctx, id) =>
  (await q(ctx, 'SELECT id, business_name, week_start FROM sellers WHERE id = ?', [id]))[0] ?? null;

// The seller's active menu, A→Z, with how many orders from `today` on include each item.
const productList = async (ctx, sellerId, today) =>
  (await q(
    ctx,
    `SELECT p.id, p.name, p.photo,
            (SELECT COUNT(DISTINCT oi.order_id) FROM order_items oi
               JOIN orders o ON o.id = oi.order_id
              WHERE oi.product_id = p.id AND o.seller_id = p.seller_id AND o.pickup_date >= ?) AS orders
       FROM products p
      WHERE p.seller_id = ? AND p.archived = 0
      ORDER BY lower(p.name), p.name`,
    [today, sellerId],
  )).map((p) => ({ id: p.id, name: p.name, photo: p.photo ?? null, orders: Number(p.orders) }));

// Orders with their items, for one seller, by a WHERE clause on `orders`.
// Waiting first and oldest saved first, picked up last (spec §2 rule 7).
const ordersWhere = async (ctx, sellerId, where, params) => {
  const list = await q(
    ctx,
    `SELECT id, customer, pickup_date, note, picked_up_at, created_at
       FROM orders WHERE seller_id = ? AND ${where}
      ORDER BY pickup_date, (picked_up_at IS NOT NULL), created_at, rowid`,
    [sellerId, ...params],
  );
  if (list.length === 0) return [];
  const marks = list.map(() => '?').join(',');
  const items = await q(
    ctx,
    `SELECT order_id, product_id, product_name, product_photo, qty FROM order_items
      WHERE order_id IN (${marks}) ORDER BY qty DESC, lower(product_name), product_name`,
    list.map((o) => o.id),
  );
  const byOrder = new Map(list.map((o) => [o.id, []]));
  for (const it of items) {
    byOrder.get(it.order_id)?.push({
      product_id: it.product_id,
      name: it.product_name,
      photo: it.product_photo ?? null,
      qty: Number(it.qty),
    });
  }
  return list.map((o) => ({
    id: o.id,
    customer: o.customer,
    pickup_date: o.pickup_date,
    note: o.note ?? null,
    picked_up: Boolean(o.picked_up_at),
    picked_up_at: o.picked_up_at ?? null,
    created_at: o.created_at,
    items: byOrder.get(o.id) ?? [],
  }));
};
