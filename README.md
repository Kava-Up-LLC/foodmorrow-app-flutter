# Foodmorrow

Know today what you cook tomorrow. For people who sell homemade food: log every order in seconds, see them by day,
and open the app to see exactly what to make tomorrow — everything added up.

Flutter (iOS + Android) on **AppAmbit** — Database, Cloud Code, Analytics and crash reports. App 04 of the
"7 apps in 7 days" series. No login, no notifications: one phone is one seller.

| File | What |
|---|---|
| `AGENTS.md` | Rules for coding agents |
| `DESIGN.md` · `design/screens/` | The look and the approved screens |
| `prompts.md` | The prompts the app is built with |
| `cloud_functions/` | The five Cloud Code functions, the schema and their tests (`cloud_functions/README.md`) |
| `assets/` | Plus Jakarta Sans (OFL) and the food photo library (Unsplash License, see `assets/food/CREDITS.md`) |
| `docs/tech/foodmorrow/` | Tech spec and user stories (local, not versioned) |

## Setup

1. Copy `.env.example` to `.env` and fill both AppAmbit App Keys.
2. `flutter pub get` · `flutter run`

Branches: `main` = the Flutter scaffold, untouched · `dev` = all the work.

## How it is put together

```
lib/
├── main.dart            dotenv → AppAmbitSdk.start → hello → runApp
├── app.dart             the four tabs under the floating tab bar
├── core/                theme tokens, dates, the photo library, shared widgets,
│   └── appambit/        …and the only place that touches the AppAmbit SDK
└── features/            welcome · home · orders · menu · settings
                         views → controllers (ChangeNotifier) → repositories → core/appambit
```

No state-management package: controllers extend `ChangeNotifier` and views rebuild with
`ListenableBuilder`. The order rules live in `lib/features/orders/order_draft.dart` as plain Dart, so they
are tested without widgets.

**Online only.** Nothing is cached: each tab reads what it needs from Cloud Code when it is shown, and a
failure becomes the "No connection" banner with Retry. Two things that came out of running it for real:

- Cloud Code calls go out **one at a time** (`AppAmbitCloudService`). Four at once never come back.
- Only the tab you are looking at is built, so opening the app is one call, not four.

## Checks

```bash
flutter analyze                          # no issues
flutter test                             # 87 unit and widget tests
node --test cloud_functions/*.test.mjs   # 22 cloud tests against in-memory SQLite
```

Against the real backend, on a real device or simulator:

```bash
flutter test integration_test/real_run_test.dart -d <device>   # the whole app, spec §9 end to end
flutter test integration_test/screen_tour_test.dart -d <device> # walks every screen slowly, for screenshots
flutter test integration_test/test_crash_test.dart -d <device>  # the test crash of spec §10 (the app goes down)
```

`real_run_test.dart` writes real rows for a throwaway seller and deletes its orders afterwards; it prints
`SELLER_ID=…` so the rest can be cleaned up.
