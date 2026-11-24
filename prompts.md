# The prompts behind Foodmorrow

Foodmorrow is for people who sell homemade food. Orders come in all day by WhatsApp; the app keeps them by day and
every night sends one notification with exactly what to make tomorrow.

> *As someone who sells homemade food, I want to log my orders and get one list every night of everything I have to
> make tomorrow, so I never forget an order or make too much.*

The app is built with **four prompts**, one per part, sent to a coding agent (Claude Code) with the **AppAmbit MCP**
connected. Each prompt ends with a commit on `dev`.

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand | The AppAmbit apps and their keys in `.env`, Firebase `google-services.json`, push credentials |
| 1 | Agent + AppAmbit MCP | The backend: database, Cloud Code, cloud tests |
| 2 | Agent + Flutter | The app: products, new order, orders by day, Tomorrow, settings |
| 3 | Agent + AppAmbit MCP + Flutter | The nightly notification, tested on both phones |
| 4 | Agent + phones | The real run, the test crash, the summary table |

Record the terminal while each prompt is pasted (1 s still before, paste, Enter, 5 s after). They go in the video.

---

## 0. By hand

1. AppAmbit: create **Foodmorrow - iOS** and **Foodmorrow - Android**. Put both App Keys in `.env` (git-ignored,
   template `.env.example`).
2. Firebase: Android app `com.kavaup.foodmorrow`; put `google-services.json` in `android/app/` (git-ignored). Upload
   the service account to **Foodmorrow - Android**.
3. iOS push: upload the APNs `.p8` to **Foodmorrow - iOS** (Sandbox & Production), bundle id `com.kavaup.foodmorrow`.

---

## 1. The backend

```text
Build the backend of Foodmorrow on AppAmbit. Use the AppAmbit MCP (call get-started-tool first)
with the apps "Foodmorrow - iOS" and "Foodmorrow - Android". Follow AGENTS.md and
docs/tech/foodmorrow/tech_foodmorrow.md (§4–§6).

Foodmorrow is for people who sell homemade food: their products, their orders by pickup day, and
every night a notification with the totals for tomorrow. No login: each phone is one seller
(seller_id).

- First check a schedule trigger fires (tiny test function every few minutes). If it doesn't,
  tell me and keep going; nightly_push also gets an HTTP trigger. Don't invent another workaround.
- FoodmorrowDb linked to BOTH apps: sellers, products, orders, order_items (spec §5).
- Cloud Code on both apps, HTTP trigger with the same name: hello, products, orders, tomorrow,
  settings, nightly_push. nightly_push also runs every hour at :00 in each app (PLATFORM env var)
  and only pushes to that app's sellers at their own local hour, once a night, only with orders.
- Every function only touches the rows of the seller_id it gets.
- Unit tests against a real in-memory SQLite (cloud_functions/foodmorrow.test.mjs). Then call the
  functions for real with a test seller (products, 3 orders for tomorrow, the totals) and delete
  the test data.
- Commit on dev: "Backend: FoodmorrowDb and Cloud Code".
```

## 2. The app

```text
Build the Foodmorrow app in Flutter for iPhone and Android. Follow AGENTS.md,
docs/tech/foodmorrow/tech_foodmorrow.md (§3, §7, §8), the user stories in
docs/tech/foodmorrow/hus_foodmorrow.md and DESIGN.md. The backend from the last step is live.

- Change the app id to com.kavaup.foodmorrow on both platforms with the change_app_package_name
  package (dev dependency), display name Foodmorrow, Android minSdk 24. Keys are in .env.
- No state-management packages: ChangeNotifier controllers + ListenableBuilder, no setState for
  app data. Every AppAmbit call in lib/core/appambit/. Order rules in plain Dart, tested.
- Three tabs: Orders (day strip + the ticket rail + New order), Tomorrow (the totals + who picks up
  what), Products. New order in under 15 seconds: customer, − / + per product, pickup Today /
  Tomorrow / Pick a date, note. Settings for the notification hour, opened from Tomorrow.
- Online only: "No connection" + Retry on every screen. Analytics events from spec §8.
- Long-press the "Foodmorrow" title on Orders = test crash.
- flutter analyze clean, flutter test green. Commit on dev: "App: orders, tomorrow and products".
```

## 3. The nightly notification

```text
Add the nightly notification to Foodmorrow. Follow AGENTS.md and the push notes in
../rushagram_app/prompts.md (Firebase BoM, google-services plugin only if the file exists,
APS_ENVIRONMENT per build config). Push credentials are already uploaded in both AppAmbit apps.

- appambit_sdk_push_notifications on both platforms. Ask for permission once, after the first
  saved order: "Get tomorrow's list every night?" · Not now / Turn on.
- Tapping the notification opens the Tomorrow tab.
- Test it for real on my iPhone and my Android: 3 orders for tomorrow, set the hour to now,
  call nightly_push over HTTP for each app, and check the title says
  "Tomorrow: 48 Cookies, 3 Chocolate cakes, 1 Lasagna".
- Commit on dev: "Push: tomorrow's list every night".
```

## 4. The real run

```text
Run Foodmorrow on my iPhone and my Android and walk through spec §9 one by one. Fix what fails.
Then trigger the test crash on each phone and check it shows up in Diagnostics.
End with the "What the agent did" table from AGENTS.md. Commit on dev: "Ready for the video".
```
