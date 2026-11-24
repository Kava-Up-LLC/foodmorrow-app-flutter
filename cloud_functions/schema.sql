-- FoodmorrowDb — run once in the AppAmbit SQL editor (or with execute-database-statement-tool).
-- One seller = one phone. Timestamps come from the database clock; pickup_date comes from the phone.
CREATE TABLE IF NOT EXISTS sellers (
  id            TEXT PRIMARY KEY,                     -- seller_id from the phone (uuid v4)
  platform      TEXT NOT NULL CHECK (platform IN ('ios','android')),
  business_name TEXT NOT NULL DEFAULT 'My kitchen',   -- 1..40 chars, shown on Home
  week_start    TEXT NOT NULL DEFAULT 'mon' CHECK (week_start IN ('mon','sun')),
  created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
  id         TEXT PRIMARY KEY,
  seller_id  TEXT NOT NULL REFERENCES sellers(id),
  name       TEXT NOT NULL,                           -- 1..40 chars, unique per seller among non-archived
  photo      TEXT,                                    -- key in the photo library ('cookies'), or NULL
  archived   INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  id           TEXT PRIMARY KEY,
  seller_id    TEXT NOT NULL REFERENCES sellers(id),
  customer     TEXT NOT NULL,                         -- 1..40 chars
  pickup_date  TEXT NOT NULL,                         -- 'YYYY-MM-DD', the seller's calendar
  note         TEXT,                                  -- 0..140 chars
  picked_up_at TEXT,                                  -- NULL = waiting
  created_at   TEXT NOT NULL,
  updated_at   TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
  order_id      TEXT NOT NULL REFERENCES orders(id),
  product_id    TEXT NOT NULL REFERENCES products(id),
  product_name  TEXT NOT NULL,                        -- copied at save time
  product_photo TEXT,                                 -- copied at save time
  qty           INTEGER NOT NULL,                     -- 1..999
  PRIMARY KEY (order_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_orders_day ON orders(seller_id, pickup_date);
-- One active name per seller, case-insensitive (spec §2 rule 4). Archived rows are left out so a
-- removed name can be used again.
CREATE UNIQUE INDEX IF NOT EXISTS idx_products_name ON products(seller_id, lower(name)) WHERE archived = 0;
