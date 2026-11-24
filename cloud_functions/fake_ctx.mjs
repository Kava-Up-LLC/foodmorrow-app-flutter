// Test helper: a ctx like AppAmbit's, backed by a real in-memory SQLite with FoodmorrowDb's schema.
// Rows come back positional with their column names, the way Cloud Code hands them over.
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';

const here = new URL('.', import.meta.url);
export const SCHEMA = readFileSync(new URL('schema.sql', here), 'utf8');

export const newDb = () => {
  const db = new DatabaseSync(':memory:');
  db.exec(SCHEMA);
  return db;
};

const run = (db, sql, params = []) => {
  const st = db.prepare(sql);
  if (/^\s*(select|with)/i.test(sql)) {
    const out = st.all(...params);
    const columns = out.length ? Object.keys(out[0]) : [];
    return { columns, rows: out.map((r) => columns.map((c) => r[c])), rows_read: out.length, rows_written: 0 };
  }
  const info = st.run(...params);
  return { columns: [], rows: [], rows_read: 0, rows_written: Number(info.changes) };
};

export const fakeCtx = ({ db = newDb(), body = {}, consumer = null, env = {} } = {}) => ({
  db,
  ctx: {
    req: { body },
    consumer,
    env,
    secrets: {},
    log: () => {},
    appambit: {
      db: async (sql, params = []) => ({ results: [run(db, sql, params)] }),
      // transaction=true also reports the BEGIN/COMMIT, exactly like the platform does.
      batch: async (statements, transaction = false) => {
        const results = [];
        if (transaction) {
          db.exec('BEGIN');
          results.push({ columns: [], rows: [], rows_read: 0, rows_written: 0 });
        }
        try {
          for (const { sql, params } of statements) results.push(run(db, sql, params));
        } catch (e) {
          if (transaction) db.exec('ROLLBACK');
          throw e;
        }
        if (transaction) {
          db.exec('COMMIT');
          results.push({ columns: [], rows: [], rows_read: 0, rows_written: 0 });
        }
        return { results };
      },
    },
  },
});

/// Calls a function's handler with one body against the given database.
export const call = async (handler, db, body) => handler(fakeCtx({ db, body }).ctx);
