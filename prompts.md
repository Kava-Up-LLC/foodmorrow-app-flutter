# The prompts behind Foodmorrow

Foodmorrow is for people who sell homemade food. Orders come in all day by WhatsApp; the app keeps them by day and
Home tells you exactly what to make tomorrow, added up across every order.

> *As someone who sells homemade food, I want to log my orders in seconds and open the app to see everything I have
> to make tomorrow, so I never forget an order or make too much.*

The app is built with **three prompts**, one per part, sent to a coding agent (Claude Code) with the **AppAmbit MCP**
connected. Each prompt ends with a commit on `dev`.

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand | The two AppAmbit apps and their keys in `.env` |
| 1 | Agent + AppAmbit MCP | The backend: database, Cloud Code, cloud tests |
| 2 | Agent + Flutter | The app: welcome, home, new/edit order, orders by day, menu, settings |
| 3 | Agent + phones | The real run, the test crash, the summary table |

Record the terminal while each prompt is pasted (1 s still before, paste, Enter, 5 s after). They go in the video.

---

## 0. By hand

1. AppAmbit: create **Foodmorrow - iOS** and **Foodmorrow - Android**.
2. Put both App Keys in `.env` (git-ignored, template `.env.example`).

No Firebase and no push credentials: Foodmorrow has no notifications.

---

## 1. The backend

```text
Build the backend of Foodmorrow on AppAmbit. Use the AppAmbit MCP (call get-started-tool first)
with the apps "Foodmorrow - iOS" and "Foodmorrow - Android". Follow AGENTS.md and
docs/tech/foodmorrow/tech_foodmorrow.md (§4–§6).

Foodmorrow is for people who sell homemade food: their menu with photos, their orders by pickup
day, and what to make tomorrow added up. No login: each phone is one seller (seller_id).

- FoodmorrowDb linked to BOTH apps: sellers, products, orders, order_items (spec §5).
- Cloud Code on both apps, HTTP trigger with the same name: hello, profile, products, orders, home.
- Every function only touches the rows of the seller_id it gets. The phone sends today/tomorrow.
- Unit tests against a real in-memory SQLite (cloud_functions/foodmorrow.test.mjs). Then call the
  functions for real with a test seller: 3 menu items, the 3 orders from spec §9 for tomorrow,
  check home says 52 things to make, then delete the test data.
- Commit on dev: "Backend: FoodmorrowDb and Cloud Code".
```

## 2. The app

```text
Build the Foodmorrow app in Flutter for iPhone and Android. Follow AGENTS.md,
docs/tech/foodmorrow/tech_foodmorrow.md (§2, §3, §7, §8), the user stories in
docs/tech/foodmorrow/hus_foodmorrow.md, DESIGN.md and the screens in design/screens/ (open them).
The backend from the last step is live.

- Change the app id to com.kavaup.foodmorrow on both platforms with the change_app_package_name
  package (dev dependency), display name Foodmorrow, Android minSdk 24. Keys are in .env.
- No state-management packages: ChangeNotifier controllers + ListenableBuilder, no setState for
  app data. Every AppAmbit call in lib/core/appambit/. Order rules in plain Dart, tested.
- Theme tokens from DESIGN.md in lib/core/theme/. Plus Jakarta Sans and the food photos are
  already in assets/.
- Floating tab bar: Home, Orders, + (new order), Menu, Settings. Welcome on first open.
- Every screen in spec §7.3 matching its PNG. New order in under 15 seconds.
- Online only: "No connection" + Retry on every screen. Analytics events from spec §8.
- Long-press the "Orders" title = test crash.
- flutter analyze clean, flutter test green. Commit on dev: "App: home, orders and menu".
```

## 3. The real run

```text
Run Foodmorrow on my iPhone and my Android and walk through spec §9 and every user story one by
one. Compare each screen with design/screens/ and fix what doesn't match. Then trigger the test
crash on each phone and check it shows up in Diagnostics.
End with the "What the agent did" table from AGENTS.md. Commit on dev: "Ready for the video".
```
