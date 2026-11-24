# Foodmorrow

Your orders today, your list for tomorrow. For people who sell homemade food: log every order in seconds, see them
by pickup day, and get one notification every night with exactly what to make tomorrow.

Flutter (iOS + Android) on **AppAmbit** — Database, Cloud Code, Push, Analytics and crash reports. App 04 of the
"7 apps in 7 days" series.

| File | What |
|---|---|
| `AGENTS.md` | Rules for coding agents |
| `DESIGN.md` | The look |
| `prompts.md` | The prompts the app is built with |
| `docs/tech/foodmorrow/` | Tech spec and user stories (local, not versioned) |

## Setup

1. Copy `.env.example` to `.env` and fill both AppAmbit App Keys.
2. Put `google-services.json` in `android/app/`.
3. `flutter pub get` · `flutter run`

Branches: `main` = the Flutter scaffold, untouched · `dev` = all the work.
