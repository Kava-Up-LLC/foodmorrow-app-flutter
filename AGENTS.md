# AGENTS.md — foodmorrow_app (Foodmorrow)

Guide for any coding agent (Claude Code, Codex, Cursor…) working in this repo. Read it first.
Behavioral guidelines in the parent `../CLAUDE.md` (apps_cms) apply here too: think first, keep it simple,
touch only what you must, verify.

## What this is

Foodmorrow — orders for people who sell homemade food. Log every order in seconds; Home tells you exactly what to make
tomorrow. A Flutter app (iOS + Android) on AppAmbit: Database, Cloud Code, Analytics and crash reports.
App 04 of the "7 apps in 7 days" series. **No notifications** (decided 2026-11-24).

## Source of truth

| File | Defines |
|---|---|
| **`docs/tech/foodmorrow/tech_foodmorrow.md`** | Everything: scope (6 features, nothing more), rules, data model, the cloud functions, folder structure, how state works, screens, acceptance criteria, risks. |
| `docs/tech/foodmorrow/hus_foodmorrow.md` | The user stories with Given/When/Then acceptance criteria. |
| `DESIGN.md` + `design/screens/*.png` | The look: tokens, components and the 10 approved screens. Open the PNGs before building a screen. |
| `prompts.md` | The prompts the app is built with, one per part. |

Build only what the spec describes. If something is missing or unclear, ask — don't invent features.

## Hard rules

1. **No state-management packages** (`provider`, `riverpod`, `bloc`, `get_it`, `mobx`…). Controllers extend
   `ChangeNotifier`; views use `ListenableBuilder`. **No `setState` for app data** (spec §7.2).
2. **No other packages** than the ones in spec §3 without asking. **No push or local notification packages.**
3. All AppAmbit SDK calls live in `lib/core/appambit/`. Views never touch the SDK.
4. **The phone never writes to the database.** Everything goes through Cloud Code, always with the `seller_id`, and a
   function only touches that seller's rows.
5. Timestamps come from the database clock. Pickup dates, "today" and "tomorrow" come from the phone (`YYYY-MM-DD`).
6. Online only: no cache, no queue, no sync-later. Network failure → "No connection" banner + Retry.
7. Screens in English. No login, no accounts.
8. Never print, paste or commit App Keys or `.env`.
9. Work on branch **`dev`**. Never commit to `main`. Commit at the end of each prompt, clear messages.
   `docs/` is local only (git-ignored) — never force-add it.
10. In UI copy, comments for the video and summaries, don't say "server" — say "AppAmbit" or "the cloud".
11. Design: match `DESIGN.md` and `design/screens/`. Colors, type and radii come from `lib/core/theme/`, never
    hard-coded in views. Fonts and food photos are already in `assets/`; don't download others.
12. App id: change it with the `change_app_package_name` package, not by hand.
13. Test crash: long-press the "Orders" title on the Orders tab → `AppAmbitSdk.generateTestCrash()` (spec §10).

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

- `../rushagram_app/cloud_functions/` — Cloud Code contract, `fake_ctx.mjs`, tests against in-memory SQLite.
- `../rushagram_app/lib/core/appambit/` and `lib/main.dart` — SDK start with per-platform keys, error mapping,
  test crash. Skip everything about push.

Take the SDK knowledge and the patterns, not their features.

## At the end

End with a short table: **What the agent did** — one column for **AppAmbit**, one for **the Foodmorrow app** — in plain
words, with counts (tables, functions, screens, tests). It goes on screen in the video.
