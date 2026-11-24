# Cloud Code — Foodmorrow

Five functions on AppAmbit Cloud Code. Both AppAmbit apps (**Foodmorrow App - iOS** and
**Foodmorrow App - Android**) share the database **FoodmorrowDb** (id 331), so the same seller sees the same
orders whichever phone they are on.

| Function | Trigger | In | Out |
|---|---|---|---|
| `hello` | HTTP, both apps | `{ seller_id, platform }` | `{ ok, business_name, week_start }` — upserts the seller. Called on every app start. |
| `profile` | HTTP, both apps | `{ seller_id, business_name?, week_start? }` | `{ ok, business_name, week_start }` — changes only the fields it is given. |
| `products` | HTTP, both apps | `{ seller_id, action: "list" \| "add" \| "edit" \| "remove", today, id?, name?, photo? }` | `{ ok, products: [{ id, name, photo, orders }] }` — active items A→Z. Every action answers with the whole menu. |
| `orders` | HTTP, both apps | `{ seller_id, action: "week" \| "search" \| "get" \| "save" \| "picked_up" \| "delete", … }` | see below |
| `home` | HTTP, both apps | `{ seller_id, today, tomorrow }` | `{ ok, business_name, tomorrow: {…}, today: {…} }` |

`orders` by action: `week` (`from`, `to`) → `{ ok, days: [{ date, orders: [Order] }] }`, every day in the range
including the empty ones · `search` (`today`, `q`) → `{ ok, results: [{ date, order }] }` from today on ·
`get` (`id`) → `{ ok, order }` · `save` (`order`, `today`) → `{ ok, id }`, an insert, or an update when
`order.id` is set · `picked_up` (`id`, `picked_up`) and `delete` (`id`) → `{ ok }`.

`Order` = `{ id, customer, pickup_date, note, picked_up, picked_up_at, created_at, items: [{ product_id, name, photo, qty }] }`.

Errors are `{ ok: false, error: "BAD_INPUT" | "DUPLICATE" | "NOT_FOUND" }`.

## The rules these functions keep

- **One seller, their own rows.** Every function takes `seller_id` and every statement is filtered by it. A seller
  can't read, change or delete another seller's menu or orders — there is a test for each of those.
- **Dates come from the phone** (spec §2 rule 2). `today` and `tomorrow` are sent in; the cloud never works out what
  day it is. Only the timestamps (`created_at`, `updated_at`, `picked_up_at`) come from the database clock.
- **A new order is for today … +60 days**; an edit may keep a day that has already passed (rule 5).
- **Totals count every order of the day, picked up or not** — they all still had to be made (rule 6).
- **A day's orders are waiting first, oldest saved first, picked up last** (rule 7).
- **Removing a menu item archives it.** It leaves the menu and New order; orders that already have it keep its name
  and photo, which were copied into `order_items` when the order was saved (rule 4).
- **An order and its items are written together** with `ctx.appambit.batch(..., true)`, so the app never reads half
  an order.

## Decisions taken while building, worth knowing

- **`created_at` has milliseconds** (`strftime('%Y-%m-%d %H:%M:%f','now')`, not `datetime('now')` as spec §5 says).
  With whole seconds, two orders saved in the same second tied and "oldest saved first" became arbitrary. The final
  tie-break is `rowid`, which is the order they were inserted in.
- **Search folds case in JavaScript, not in SQL.** SQLite's `lower()` only folds ASCII, so `SOFÍA` would not have
  matched `Sofía` — which is most of this app's customers. Only the days from today on are read.
- **Tomorrow's list groups by `product_id`** and shows the menu's current name and photo when the item is still on
  the menu, so renaming an item doesn't split tomorrow's list in two.
- **`Order` carries `picked_up_at`**, which spec §6 doesn't list. The timeline on Order details needs the date.
- **`products` needs `today`** for every action, not just `list`, because every action answers with the menu and
  the menu carries the "In N orders" count.

## The files

`_shared.mjs` + `parts/<name>.mjs` are the source; `<name>.mjs` is what gets deployed. Cloud Code deploys one file
per function, so the shared helpers have to be inside each one. **Never edit `hello.mjs`, `profile.mjs`,
`products.mjs`, `orders.mjs` or `home.mjs` by hand** — change `_shared.mjs` or the part, then:

```bash
node cloud_functions/make.mjs
```

## Database

`schema.sql`: 4 tables, the day index, and a unique index on `(seller_id, lower(name)) WHERE archived = 0` so a
seller can't have the same item twice, however they type it — and so a removed name can be used again.

⚠️ When running the DDL through the AppAmbit MCP, strip the `--` comments first: the tool's SQL guard rejects
statements that carry them.

## Tests

Against a real in-memory SQLite with this schema (`fake_ctx.mjs`, which fakes `db` and `batch`):

```bash
node --test cloud_functions/*.test.mjs
```

22 tests: sellers can't see each other, totals add up across orders and ignore other days, picked up still counts,
editing replaces items, an archived item keeps old orders, a week is 7 days, search ignores case and past days,
and every rule above that can be broken by bad input.
