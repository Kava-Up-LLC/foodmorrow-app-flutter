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
failure becomes the "No connection" banner with Retry. Four things that came out of running it for real:

- Cloud Code calls go out **one at a time** (`AppAmbitCloudService`). Four at once never come back.
- Only the tab you are looking at is built, so opening the app is one call, not four.
- **The first frame never waits on the network.** `hello` is started, not awaited; the shell picks it up
  when it lands. Awaiting it meant a white screen for as long as the call took.
- **Everything that loads shimmers** (`core/widgets/shimmer.dart`), in the shape of the content that is
  coming — the menu's 2-column grid, Home's cards, the order rows — so nothing jumps when it arrives.
  With "reduce motion" the placeholders stand still.

## Checks

```bash
flutter analyze                          # no issues
flutter test                             # 91 unit and widget tests
node --test cloud_functions/*.test.mjs   # 22 cloud tests against in-memory SQLite
```

Against the real backend, on a real device or simulator:

```bash
flutter test integration_test/real_run_test.dart -d <device>   # the whole app, spec §9 end to end
flutter test integration_test/screen_tour_test.dart -d <device> # walks every screen slowly, for screenshots
flutter test integration_test/test_crash_test.dart -d <device>  # the test crash of spec §10 (the app goes down)
flutter test integration_test/seed_demo_data_test.dart -d <device> # fills the phone with the demo data
```

`real_run_test.dart` writes real rows for a throwaway seller and deletes its orders afterwards; it prints
`SELLER_ID=…` so the rest can be cleaned up.

## Demo data

To fill a phone with Ana's Kitchen — four menu items and the orders of spec §9, so tomorrow adds up to
52 things to make:

```bash
flutter test integration_test/seed_demo_data_test.dart -d <device>
flutter run -d <device>
```

It writes through the app's own repositories, so everything lands in AppAmbit exactly as the app would
put it there, and it marks the first open as done. Run it again and it tops the data back up: items it
already has are left alone and the next few days of orders are rebuilt.

One catch on the iOS **simulator**: each install gets a fresh container, so the phone forgets which
seller it was and you land back on Welcome. On a real phone, where the app is installed once, the seller
sticks and the data is there when you open it.
