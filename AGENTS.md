# AGENTS.md — foodmorrow_app (Foodmorrow)

Guide for any coding agent (Claude Code, Codex, Cursor…) working in this repo. Read it first.
Behavioral guidelines in the parent `../CLAUDE.md` (apps_cms) apply here too: think first, keep it simple,
touch only what you must, verify.

## What this is

Foodmorrow — orders for people who sell homemade food, and every night one notification with what to make tomorrow.
A Flutter app (iOS + Android) on AppAmbit: Database, Cloud Code (HTTP + scheduled), Push, Analytics and crash reports.
App 04 of the "7 apps in 7 days" series.

## Source of truth

| File | Defines |
|---|---|
| **`docs/tech/foodmorrow/tech_foodmorrow.md`** | Everything: scope (5 features, nothing more), rules, data model, the cloud functions, folder structure, how state works, screens, acceptance criteria, risks. |
| `docs/tech/foodmorrow/hus_foodmorrow.md` | The user stories with Given/When/Then acceptance criteria. |
| `DESIGN.md` | The look: colors, type, spacing, components, screens. |
| `prompts.md` | The prompts the app is built with, one per part. |

Build only what the spec describes. If something is missing or unclear, ask — don't invent features.

## Hard rules

1. **No state-management packages** (`provider`, `riverpod`, `bloc`, `get_it`, `mobx`…). Controllers extend
   `ChangeNotifier`; views use `ListenableBuilder`. **No `setState` for app data** (spec §7.2).
2. **No other packages** than the ones in spec §3 without asking.
3. All AppAmbit SDK calls live in `lib/core/appambit/`. Views never touch the SDK.
4. **The phone never writes to the database.** Everything goes through Cloud Code, always with the `seller_id`, and a
   function only touches that seller's rows.
5. Timestamps come from the database clock. Pickup dates are the seller's calendar (`YYYY-MM-DD` from the phone).
6. Online only: no cache, no queue, no sync-later. Network failure → "No connection" banner + Retry.
7. Screens in English. No login, no accounts.
8. Never print, paste or commit App Keys, `.env`, `google-services.json` secrets or push credentials.
9. Work on branch **`dev`**. Never commit to `main`. Commit at the end of each prompt, clear messages.
   `docs/` is local only (git-ignored) — never force-add it.
10. In UI copy, comments for the video and summaries, don't say "server" — say "AppAmbit" or "the cloud".
11. Push from the cloud: `ctx.appambit.push({ title, body, data, consumer_id })` inside Cloud Code. It only reaches
    phones of the AppAmbit app the function runs in, so `nightly_push` runs in **each** app for its own sellers
    (`PLATFORM` env var). A seller's `consumer_id` is saved by `hello` from `ctx.consumer.id`.
12. Design: match `DESIGN.md`.
13. App id: change it with the `change_app_package_name` package, not by hand.
14. Test crash: long-press the "Foodmorrow" title on Orders → `AppAmbitSdk.generateTestCrash()` (spec §10).

## Commands

```bash
flutter pub get
flutter analyze
flutter test
node --test cloud_functions/*.test.mjs
flutter run -d <device>          # flutter devices
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Reference code (read, don't copy blindly)

- `../rushagram_app/cloud_functions/` — Cloud Code contract, `fake_ctx.mjs`, tests against in-memory SQLite, push by
  `consumer_id` per app, the README notes on triggers.
- `../rushagram_app/lib/core/appambit/` and `lib/main.dart` — SDK start with per-platform keys, push start, error
  mapping, test crash.
- `../rushagram_app/prompts.md` and `../app_shoplist/prompts.md` — the push setup that works (Firebase BoM,
  google-services plugin only if the file exists, `APS_ENVIRONMENT` per build config).

Take the SDK knowledge and the patterns, not their features.

## At the end

End with a short table: **What the agent did** — one column for **AppAmbit**, one for **the Foodmorrow app** — in plain
words, with counts (tables, functions, screens, tests). It goes on screen in the video.
