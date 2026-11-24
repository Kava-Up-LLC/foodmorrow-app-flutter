# Foodmorrow

Know today what you cook tomorrow. For people who sell homemade food: log every order in seconds, see them by day,
and open the app to see exactly what to make tomorrow — everything added up.

Flutter (iOS + Android) on **AppAmbit** — Database, Cloud Code, Analytics and crash reports. App 04 of the
"7 apps in 7 days" series.

| File | What |
|---|---|
| `AGENTS.md` | Rules for coding agents |
| `DESIGN.md` · `design/screens/` | The look and the approved screens |
| `prompts.md` | The prompts the app is built with |
| `assets/` | Plus Jakarta Sans (OFL) and the food photo library (Unsplash License, see `assets/food/CREDITS.md`) |
| `docs/tech/foodmorrow/` | Tech spec and user stories (local, not versioned) |

## Setup

1. Copy `.env.example` to `.env` and fill both AppAmbit App Keys.
2. `flutter pub get` · `flutter run`

Branches: `main` = the Flutter scaffold, untouched · `dev` = all the work.
