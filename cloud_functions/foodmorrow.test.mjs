// Unit tests for the Foodmorrow Cloud Code functions, against a real in-memory SQLite with
// FoodmorrowDb's schema. Run: node --test cloud_functions/*.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';

import { newDb, call } from './fake_ctx.mjs';
import { handler as hello } from './hello.mjs';
import { handler as profile } from './profile.mjs';
import { handler as products } from './products.mjs';
import { handler as orders } from './orders.mjs';
import { handler as home } from './home.mjs';

const ANA = '11111111-1111-4111-8111-111111111111';
const BOB = '22222222-2222-4222-8222-222222222222';
const TODAY = '2026-11-24';
const TOMORROW = '2026-11-25';

/// A database with Ana (and optionally Bob) already said hello.
const setup = async (sellers = [ANA]) => {
  const db = newDb();
  for (const id of sellers) await call(hello, db, { seller_id: id, platform: 'ios' });
  return db;
};

/// Adds menu items and returns { name: id }.
const menu = async (db, sellerId, names) => {
  const out = {};
  for (const name of names) {
    const res = await call(products, db, {
      seller_id: sellerId, action: 'add', today: TODAY, name, photo: name.toLowerCase().replace(/\W+/g, '_'),
    });
    assert.equal(res.ok, true, `adding ${name}: ${JSON.stringify(res)}`);
    out[name] = res.products.find((p) => p.name === name).id;
  }
  return out;
};

const save = (db, sellerId, customer, date, items, extra = {}) =>
  call(orders, db, {
    seller_id: sellerId, action: 'save', today: TODAY,
    order: { customer, pickup_date: date, items, ...extra },
  });

// ---------------------------------------------------------------- hello / profile

test('hello creates the seller once and hands back the defaults', async () => {
  const db = newDb();
  const first = await call(hello, db, { seller_id: ANA, platform: 'ios' });
  assert.deepEqual(first, { ok: true, business_name: 'My kitchen', week_start: 'mon' });

  await call(profile, db, { seller_id: ANA, business_name: "Ana's Kitchen", week_start: 'sun' });
  // A second start must not wipe what the seller set.
  const again = await call(hello, db, { seller_id: ANA, platform: 'android' });
  assert.deepEqual(again, { ok: true, business_name: "Ana's Kitchen", week_start: 'sun' });
});

test('profile only changes what it is given, and refuses the rest', async () => {
  const db = await setup();
  assert.deepEqual(await call(profile, db, { seller_id: ANA }), {
    ok: true, business_name: 'My kitchen', week_start: 'mon',
  });
  assert.deepEqual(await call(profile, db, { seller_id: ANA, week_start: 'sun' }), {
    ok: true, business_name: 'My kitchen', week_start: 'sun',
  });
  assert.equal((await call(profile, db, { seller_id: ANA, week_start: 'tue' })).error, 'BAD_INPUT');
  assert.equal((await call(profile, db, { seller_id: ANA, business_name: '   ' })).error, 'BAD_INPUT');
  assert.equal((await call(profile, db, { seller_id: ANA, business_name: 'x'.repeat(41) })).error, 'BAD_INPUT');
  assert.equal((await call(profile, db, { seller_id: BOB })).error, 'NOT_FOUND');
  // The refused calls changed nothing.
  assert.deepEqual(await call(profile, db, { seller_id: ANA }), {
    ok: true, business_name: 'My kitchen', week_start: 'sun',
  });
});

// ---------------------------------------------------------------- the menu

test('the menu is A→Z, names are unique per seller however they are typed', async () => {
  const db = await setup();
  await menu(db, ANA, ['Lasagna', 'Cookies']);
  const list = await call(products, db, { seller_id: ANA, action: 'list', today: TODAY });
  assert.deepEqual(list.products.map((p) => p.name), ['Cookies', 'Lasagna']);
  assert.deepEqual(list.products.map((p) => p.photo), ['cookies', 'lasagna']);

  const dup = await call(products, db, { seller_id: ANA, action: 'add', today: TODAY, name: 'cookies' });
  assert.equal(dup.error, 'DUPLICATE');
  assert.equal((await call(products, db, { seller_id: ANA, action: 'list', today: TODAY })).products.length, 2);
});

test('a menu item can be renamed, and old orders keep the name they were saved with', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  const saved = await save(db, ANA, 'Laura', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);
  assert.equal(saved.ok, true);

  const renamed = await call(products, db, {
    seller_id: ANA, action: 'edit', today: TODAY, id: ids.Cookies, name: 'Choc chip cookies', photo: 'cookies',
  });
  assert.equal(renamed.products[0].name, 'Choc chip cookies');

  const order = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(order.order.items[0].name, 'Cookies', 'the order keeps the old name');
});

test('removing a menu item takes it off the menu and leaves old orders alone', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies', 'Lasagna']);
  const saved = await save(db, ANA, 'Sofía', TOMORROW, [
    { product_id: ids.Cookies, qty: 12 }, { product_id: ids.Lasagna, qty: 1 },
  ]);

  const left = await call(products, db, { seller_id: ANA, action: 'remove', today: TODAY, id: ids.Lasagna });
  assert.deepEqual(left.products.map((p) => p.name), ['Cookies']);

  const order = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.deepEqual(order.order.items.map((i) => i.name).sort(), ['Cookies', 'Lasagna']);
  // And the day's totals still list it.
  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.deepEqual(h.tomorrow.items.map((i) => i.name), ['Cookies', 'Lasagna']);
  // Removing it twice is a NOT_FOUND, not a second archive.
  assert.equal((await call(products, db, { seller_id: ANA, action: 'remove', today: TODAY, id: ids.Lasagna })).error, 'NOT_FOUND');
  // The freed name can be used again.
  assert.equal((await call(products, db, { seller_id: ANA, action: 'add', today: TODAY, name: 'Lasagna' })).ok, true);
});

test('each menu item says how many orders from today on include it', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  await save(db, ANA, 'Laura', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);
  await save(db, ANA, 'Pedro', TOMORROW, [{ product_id: ids.Cookies, qty: 24 }]);
  // An order that has already been picked up, on a day gone by, must not count.
  await call(orders, db, {
    seller_id: ANA, action: 'save',
    order: { customer: 'Old', pickup_date: '2026-11-01', items: [{ product_id: ids.Cookies, qty: 5 }] },
  });

  const list = await call(products, db, { seller_id: ANA, action: 'list', today: TODAY });
  assert.equal(list.products[0].orders, 2);
});

test('the menu refuses what it should', async () => {
  const db = await setup();
  for (const body of [
    { seller_id: 'x', action: 'list', today: TODAY },
    { seller_id: ANA, action: 'nope', today: TODAY },
    { seller_id: ANA, action: 'list', today: '24/11/2026' },
    { seller_id: ANA, action: 'list', today: '2026-02-30' },
    { seller_id: ANA, action: 'add', today: TODAY, name: '' },
    { seller_id: ANA, action: 'add', today: TODAY, name: 'x'.repeat(41) },
    { seller_id: ANA, action: 'add', today: TODAY, name: 'Pie', photo: '../secret.jpg' },
    { seller_id: ANA, action: 'edit', today: TODAY, name: 'Pie' },
  ]) {
    assert.equal((await call(products, db, body)).error, 'BAD_INPUT', JSON.stringify(body));
  }
  assert.equal((await call(products, db, {
    seller_id: ANA, action: 'edit', today: TODAY, id: '99999999-9999-4999-8999-999999999999', name: 'Pie',
  })).error, 'NOT_FOUND');
});

// ---------------------------------------------------------------- orders

test('a saved order comes back whole', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies', 'Chocolate cake']);
  const saved = await save(db, ANA, '  Laura  ', TOMORROW, [
    { product_id: ids.Cookies, qty: 12 }, { product_id: ids['Chocolate cake'], qty: 1 },
  ], { note: 'No nuts' });
  assert.equal(saved.ok, true);

  const { order } = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(order.customer, 'Laura', 'the name is trimmed');
  assert.equal(order.pickup_date, TOMORROW);
  assert.equal(order.note, 'No nuts');
  assert.equal(order.picked_up, false);
  // Largest first, the way the order card and Order details show them (ties A→Z).
  assert.deepEqual(order.items.map((i) => [i.name, i.qty]), [['Cookies', 12], ['Chocolate cake', 1]]);
  assert.equal(order.items[0].photo, 'cookies');
});

test('editing an order replaces its items instead of adding to them', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies', 'Chocolate cake', 'Lasagna']);
  const saved = await save(db, ANA, 'Sofía', TOMORROW, [
    { product_id: ids.Cookies, qty: 12 }, { product_id: ids['Chocolate cake'], qty: 2 },
  ]);

  const edited = await call(orders, db, {
    seller_id: ANA, action: 'save', today: TODAY,
    order: {
      id: saved.id, customer: 'Sofía Ramos', pickup_date: TOMORROW,
      items: [{ product_id: ids['Chocolate cake'], qty: 3 }, { product_id: ids.Lasagna, qty: 1 }],
    },
  });
  assert.deepEqual(edited, { ok: true, id: saved.id });

  const { order } = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(order.customer, 'Sofía Ramos');
  assert.deepEqual(order.items.map((i) => [i.name, i.qty]), [['Chocolate cake', 3], ['Lasagna', 1]]);
  assert.deepEqual(
    (await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id })).order.items.map((i) => i.qty),
    [3, 1],
    'largest first',
  );
});

test('an edit may keep a pickup day that has already passed', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  // Saved without `today`, so no window is applied: this is the order that is already in the past.
  const saved = await call(orders, db, {
    seller_id: ANA, action: 'save',
    order: { customer: 'Marta', pickup_date: '2026-11-01', items: [{ product_id: ids.Cookies, qty: 2 }] },
  });
  const edited = await call(orders, db, {
    seller_id: ANA, action: 'save', today: TODAY,
    order: { id: saved.id, customer: 'Marta', pickup_date: '2026-11-01', items: [{ product_id: ids.Cookies, qty: 4 }] },
  });
  assert.equal(edited.ok, true);
  // A brand new order for that same day is refused.
  assert.equal((await save(db, ANA, 'Marta', '2026-11-01', [{ product_id: ids.Cookies, qty: 4 }])).error, 'BAD_INPUT');
  // So is one more than 60 days out.
  assert.equal((await save(db, ANA, 'Marta', '2027-03-01', [{ product_id: ids.Cookies, qty: 4 }])).error, 'BAD_INPUT');
  assert.equal((await save(db, ANA, 'Marta', '2027-01-23', [{ product_id: ids.Cookies, qty: 4 }])).ok, true);
});

test('save refuses an order that breaks the rules', async () => {
  const db = await setup([ANA, BOB]);
  const ids = await menu(db, ANA, ['Cookies']);
  const bobs = await menu(db, BOB, ['Tamales']);
  const one = [{ product_id: ids.Cookies, qty: 1 }];

  const bad = [
    { customer: '', pickup_date: TOMORROW, items: one },
    { customer: 'x'.repeat(41), pickup_date: TOMORROW, items: one },
    { customer: 'Laura', pickup_date: 'tomorrow', items: one },
    { customer: 'Laura', pickup_date: TOMORROW, items: [] },
    { customer: 'Laura', pickup_date: TOMORROW, items: [{ product_id: ids.Cookies, qty: 0 }] },
    { customer: 'Laura', pickup_date: TOMORROW, items: [{ product_id: ids.Cookies, qty: 1000 }] },
    { customer: 'Laura', pickup_date: TOMORROW, items: [{ product_id: ids.Cookies, qty: 1.5 }] },
    { customer: 'Laura', pickup_date: TOMORROW, items: [{ product_id: ids.Cookies, qty: 1 }, { product_id: ids.Cookies, qty: 2 }] },
    { customer: 'Laura', pickup_date: TOMORROW, items: [{ product_id: bobs.Tamales, qty: 1 }] },
    { customer: 'Laura', pickup_date: TOMORROW, items: one, note: 'x'.repeat(141) },
  ];
  for (const order of bad) {
    const res = await call(orders, db, { seller_id: ANA, action: 'save', today: TODAY, order });
    assert.equal(res.error, 'BAD_INPUT', JSON.stringify(order));
  }
  assert.equal((await call(orders, db, { seller_id: ANA, action: 'save', today: TODAY })).error, 'BAD_INPUT');
  // Nothing of all that was written.
  const week = await call(orders, db, { seller_id: ANA, action: 'week', from: TODAY, to: '2026-11-30' });
  assert.equal(week.days.reduce((n, d) => n + d.orders.length, 0), 0);
});

test('editing an order that is not yours is a NOT_FOUND, and leaves it untouched', async () => {
  const db = await setup([ANA, BOB]);
  const ids = await menu(db, ANA, ['Cookies']);
  const saved = await save(db, ANA, 'Laura', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);
  const bobs = await menu(db, BOB, ['Tamales']);

  for (const action of ['get', 'delete']) {
    assert.equal((await call(orders, db, { seller_id: BOB, action, id: saved.id })).error, 'NOT_FOUND');
  }
  assert.equal((await call(orders, db, { seller_id: BOB, action: 'picked_up', id: saved.id, picked_up: true })).error, 'NOT_FOUND');
  assert.equal((await call(orders, db, {
    seller_id: BOB, action: 'save', today: TODAY,
    order: { id: saved.id, customer: 'Stolen', pickup_date: TOMORROW, items: [{ product_id: bobs.Tamales, qty: 1 }] },
  })).error, 'NOT_FOUND');

  const { order } = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(order.customer, 'Laura');
  assert.equal(order.items.length, 1);
});

test('two sellers never see each other', async () => {
  const db = await setup([ANA, BOB]);
  const anas = await menu(db, ANA, ['Cookies']);
  const bobs = await menu(db, BOB, ['Tamales']);
  await save(db, ANA, 'Laura', TOMORROW, [{ product_id: anas.Cookies, qty: 12 }]);
  await save(db, BOB, 'Hugo', TOMORROW, [{ product_id: bobs.Tamales, qty: 30 }]);

  const anaMenu = await call(products, db, { seller_id: ANA, action: 'list', today: TODAY });
  assert.deepEqual(anaMenu.products.map((p) => p.name), ['Cookies']);

  const anaHome = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(anaHome.tomorrow.things, 12);
  assert.deepEqual(anaHome.tomorrow.items.map((i) => i.name), ['Cookies']);

  const bobHome = await call(home, db, { seller_id: BOB, today: TODAY, tomorrow: TOMORROW });
  assert.equal(bobHome.tomorrow.things, 30);

  const anaWeek = await call(orders, db, { seller_id: ANA, action: 'week', from: TODAY, to: '2026-11-30' });
  const names = anaWeek.days.flatMap((d) => d.orders.map((o) => o.customer));
  assert.deepEqual(names, ['Laura']);

  const anaSearch = await call(orders, db, { seller_id: ANA, action: 'search', today: TODAY, q: 'hugo' });
  assert.deepEqual(anaSearch.results, []);
});

test('picked up can be undone, and a picked-up order still counts', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  const saved = await save(db, ANA, 'Marta', TOMORROW, [{ product_id: ids.Cookies, qty: 10 }]);

  assert.deepEqual(await call(orders, db, { seller_id: ANA, action: 'picked_up', id: saved.id, picked_up: true }), { ok: true });
  let got = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(got.order.picked_up, true);
  assert.equal(typeof got.order.picked_up_at, 'string');

  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(h.tomorrow.things, 10, 'it was still made');

  assert.deepEqual(await call(orders, db, { seller_id: ANA, action: 'picked_up', id: saved.id, picked_up: false }), { ok: true });
  got = await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id });
  assert.equal(got.order.picked_up, false);
  assert.equal(got.order.picked_up_at, null);

  assert.equal((await call(orders, db, { seller_id: ANA, action: 'picked_up', id: saved.id, picked_up: 'yes' })).error, 'BAD_INPUT');
});

test('deleting an order takes its items with it', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  const saved = await save(db, ANA, 'Sofía', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);

  assert.deepEqual(await call(orders, db, { seller_id: ANA, action: 'delete', id: saved.id }), { ok: true });
  assert.equal((await call(orders, db, { seller_id: ANA, action: 'get', id: saved.id })).error, 'NOT_FOUND');
  assert.equal(db.prepare('SELECT COUNT(*) AS n FROM order_items').get().n, 0);

  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(h.tomorrow.things, 0);
  assert.deepEqual(h.tomorrow.items, []);
});

test('a week is seven days, empty ones included, waiting orders first', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  const first = await save(db, ANA, 'Laura', TOMORROW, [{ product_id: ids.Cookies, qty: 1 }]);
  const second = await save(db, ANA, 'Pedro', TOMORROW, [{ product_id: ids.Cookies, qty: 2 }]);
  await save(db, ANA, 'Sofía', '2026-11-27', [{ product_id: ids.Cookies, qty: 3 }]);

  const week = await call(orders, db, { seller_id: ANA, action: 'week', from: '2026-11-23', to: '2026-11-29' });
  assert.equal(week.days.length, 7);
  assert.deepEqual(week.days.map((d) => d.date), [
    '2026-11-23', '2026-11-24', '2026-11-25', '2026-11-26', '2026-11-27', '2026-11-28', '2026-11-29',
  ]);
  assert.deepEqual(week.days.map((d) => d.orders.length), [0, 0, 2, 0, 1, 0, 0]);
  assert.deepEqual(week.days[2].orders.map((o) => o.customer), ['Laura', 'Pedro'], 'oldest saved first');

  // Picked up goes last, however early it was saved.
  await call(orders, db, { seller_id: ANA, action: 'picked_up', id: first.id, picked_up: true });
  const after = await call(orders, db, { seller_id: ANA, action: 'week', from: '2026-11-23', to: '2026-11-29' });
  assert.deepEqual(after.days[2].orders.map((o) => o.customer), ['Pedro', 'Laura']);
  assert.deepEqual(after.days[2].orders.map((o) => o.picked_up), [false, true]);
  assert.equal(second.ok, true);

  assert.equal((await call(orders, db, { seller_id: ANA, action: 'week', from: TOMORROW, to: TODAY })).error, 'BAD_INPUT');
  assert.equal((await call(orders, db, { seller_id: ANA, action: 'week', from: TODAY, to: '2027-11-24' })).error, 'BAD_INPUT');
});

test('search finds a customer however it is typed, and never looks back', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  await save(db, ANA, 'Sofía Ramos', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);
  await save(db, ANA, 'SOFIA B', '2026-11-27', [{ product_id: ids.Cookies, qty: 1 }]);
  await call(orders, db, {
    seller_id: ANA, action: 'save',
    order: { customer: 'Sofía old', pickup_date: '2026-11-01', items: [{ product_id: ids.Cookies, qty: 1 }] },
  });

  const res = await call(orders, db, { seller_id: ANA, action: 'search', today: TODAY, q: 'sof' });
  assert.deepEqual(res.results.map((r) => [r.date, r.order.customer]), [
    [TOMORROW, 'Sofía Ramos'], ['2026-11-27', 'SOFIA B'],
  ]);
  assert.deepEqual((await call(orders, db, { seller_id: ANA, action: 'search', today: TODAY, q: 'SOFÍA RAMOS' })).results.length, 1);
  assert.deepEqual((await call(orders, db, { seller_id: ANA, action: 'search', today: TODAY, q: 'zz' })).results, []);
  // A query of nothing but spaces is not a search.
  assert.equal((await call(orders, db, { seller_id: ANA, action: 'search', today: TODAY, q: '  ' })).error, 'BAD_INPUT');
});

// ---------------------------------------------------------------- home

test('Home adds tomorrow up across every order — the 52 things of spec §9', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies', 'Chocolate cake', 'Lasagna']);
  await save(db, ANA, 'Laura', TOMORROW, [
    { product_id: ids.Cookies, qty: 12 }, { product_id: ids['Chocolate cake'], qty: 1 },
  ]);
  await save(db, ANA, 'Pedro', TOMORROW, [{ product_id: ids.Cookies, qty: 24 }]);
  const sofia = await save(db, ANA, 'Sofía', TOMORROW, [
    { product_id: ids.Cookies, qty: 12 },
    { product_id: ids['Chocolate cake'], qty: 2 },
    { product_id: ids.Lasagna, qty: 1 },
  ]);
  // Another day, and it must not leak into tomorrow.
  await save(db, ANA, 'Hugo', '2026-11-27', [{ product_id: ids.Cookies, qty: 100 }]);

  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(h.business_name, 'My kitchen');
  assert.equal(h.tomorrow.date, TOMORROW);
  assert.equal(h.tomorrow.things, 52);
  assert.equal(h.tomorrow.orders, 3);
  assert.deepEqual(h.tomorrow.items.map((i) => [i.qty, i.name, i.orders]), [
    [48, 'Cookies', 3], [3, 'Chocolate cake', 2], [1, 'Lasagna', 1],
  ]);
  assert.equal(h.tomorrow.items[0].photo, 'cookies');

  // Marking one picked up changes nothing about what has to be made.
  await call(orders, db, { seller_id: ANA, action: 'picked_up', id: sofia.id, picked_up: true });
  const same = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(same.tomorrow.things, 52);

  // Editing an order does change them (HU-04 CA2).
  await call(orders, db, {
    seller_id: ANA, action: 'save', today: TODAY,
    order: {
      id: sofia.id, customer: 'Sofía', pickup_date: TOMORROW,
      items: [
        { product_id: ids.Cookies, qty: 12 },
        { product_id: ids['Chocolate cake'], qty: 3 },
        { product_id: ids.Lasagna, qty: 1 },
      ],
    },
  });
  const edited = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(edited.tomorrow.things, 53);
  assert.deepEqual(edited.tomorrow.items.map((i) => [i.qty, i.name]), [
    [48, 'Cookies'], [4, 'Chocolate cake'], [1, 'Lasagna'],
  ]);
});

test('ties in tomorrow’s list are broken A→Z', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Zucchini bread', 'Brownies', 'Apple pie']);
  await save(db, ANA, 'Laura', TOMORROW, Object.values(ids).map((id) => ({ product_id: id, qty: 5 })));
  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.deepEqual(h.tomorrow.items.map((i) => i.name), ['Apple pie', 'Brownies', 'Zucchini bread']);
});

test('Home counts today’s pickups and how many are done', async () => {
  const db = await setup();
  const ids = await menu(db, ANA, ['Cookies']);
  const marta = await save(db, ANA, 'Marta', TODAY, [{ product_id: ids.Cookies, qty: 6 }]);
  await save(db, ANA, 'Luis', TODAY, [{ product_id: ids.Cookies, qty: 2 }]);
  await save(db, ANA, 'Laura', TOMORROW, [{ product_id: ids.Cookies, qty: 12 }]);

  let h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(h.today.total, 2);
  assert.equal(h.today.done, 0);
  assert.deepEqual(h.today.pickups.map((p) => p.customer), ['Marta', 'Luis']);
  assert.deepEqual(h.today.pickups[0].items, [{ name: 'Cookies', photo: 'cookies', qty: 6 }]);

  await call(orders, db, { seller_id: ANA, action: 'picked_up', id: marta.id, picked_up: true });
  h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.equal(h.today.done, 1);
  assert.deepEqual(h.today.pickups.map((p) => [p.customer, p.picked_up]), [['Luis', false], ['Marta', true]]);
});

test('Home on a brand new phone is empty, not an error', async () => {
  const db = await setup();
  const h = await call(home, db, { seller_id: ANA, today: TODAY, tomorrow: TOMORROW });
  assert.deepEqual(h.tomorrow, { date: TOMORROW, things: 0, orders: 0, items: [] });
  assert.deepEqual(h.today, { date: TODAY, done: 0, total: 0, pickups: [] });
});

test('Home refuses a bad call and an unknown seller', async () => {
  const db = await setup();
  assert.equal((await call(home, db, { seller_id: ANA, today: TODAY })).error, 'BAD_INPUT');
  assert.equal((await call(home, db, { seller_id: ANA, today: 'today', tomorrow: TOMORROW })).error, 'BAD_INPUT');
  assert.equal((await call(home, db, { seller_id: BOB, today: TODAY, tomorrow: TOMORROW })).error, 'NOT_FOUND');
  assert.equal((await call(hello, db, { seller_id: ANA, platform: 'web' })).error, 'BAD_INPUT');
});
