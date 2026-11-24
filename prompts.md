# The prompt behind Foodmorrow

Foodmorrow is for people who sell homemade food. Orders come in all day by WhatsApp; the app keeps them by day and
Home tells you exactly what to make tomorrow, added up across every order.

> *As someone who sells homemade food, I want to log my orders in seconds and open the app to see everything I have
> to make tomorrow, so I never forget an order or make too much.*

The app is built with **one prompt** sent to a coding agent (Claude Code) with the **AppAmbit MCP** connected.

| Step | Where | What it builds |
|---|---|---|
| 0 | By hand (done) | The two AppAmbit apps and their keys in `.env` |
| 1 | Agent + AppAmbit MCP + Flutter | Everything: backend, the app, tests, the real test on two phones |

---

## 0. By hand (done 2026-11-24)

1. AppAmbit: **Foodmorrow App - iOS** and **Foodmorrow App - Android**. Both App Keys are in `.env` (git-ignored).

No Firebase and no push credentials: Foodmorrow has no notifications.

Record the terminal while the prompt is pasted (1 s still before, paste, Enter, 5 s after). It goes in the video.

---

## 1. The prompt

```text
Build Foodmorrow, an orders app for people who sell homemade food, for iPhone and Android, on
AppAmbit, from start to finish. Use the AppAmbit MCP (call get-started-tool first) with the apps
"Foodmorrow App - iOS" and "Foodmorrow App - Android". Follow AGENTS.md,
docs/tech/foodmorrow/tech_foodmorrow.md, docs/tech/foodmorrow/hus_foodmorrow.md, DESIGN.md and
the screens in design/screens/ (open them).

The idea: orders arrive all day by WhatsApp. Log each one in seconds: customer, pickup day, how
many of each item from your menu. Open the app and Home tells you what to make tomorrow, added up
across every order: "52 things to make: 48 Cookies, 3 Chocolate cake, 1 Lasagna". No login, no
notifications.

1. SET UP THE APP
- Change the app id to com.kavaup.foodmorrow on both platforms with the change_app_package_name
  package (dev dependency), display name Foodmorrow, Android minSdk 24. Keys are already in .env.

2. THE BACKEND (AppAmbit)
- FoodmorrowDb linked to BOTH apps: sellers, products, orders, order_items (spec §5).
- Cloud Code on both apps, HTTP trigger with the same name: hello, profile, products, orders,
  home. Every function only touches the rows of the seller_id it gets. The phone sends
  today/tomorrow; timestamps come from the database clock.
- Unit tests against a real in-memory SQLite. Then call the functions for real with a test
  seller: 3 menu items, the 3 orders from spec §9 for tomorrow, check home says 52 things to
  make, and delete the test data.

3. THE APP (Flutter)
- No state-management packages: ChangeNotifier controllers + ListenableBuilder, no setState for
  app data. Every AppAmbit call in lib/core/appambit/. Order rules in plain Dart, tested.
- Theme tokens from DESIGN.md in lib/core/theme/. Plus Jakarta Sans and the food photos are
  already in assets/.
- Welcome on first open → floating tab bar: Home, Orders, + (new order), Menu, Settings.
  Home: "Tomorrow · N things to make", one card per item, today's pickups with a check.
  New / edit order in under 15 seconds. Orders: week strip, order cards, details with picked up,
  edit and delete, search. Menu with photos from the library. Settings. Every screen matching
  its PNG.
- Long-press the "Orders" title calls AppAmbitSdk.generateTestCrash (for the crash demo).
- No internet: "No connection" banner with Retry on every screen. Analytics events from spec §8.

4. PROVE IT
- flutter analyze clean, flutter test and node --test green.
- Real test on a real iPhone and a real Android phone: walk spec §9 and every user story, Home
  shows 52 things to make, editing an order changes the totals, and the test crash shows up in
  Diagnostics on both.

End with a table "What the agent did": AppAmbit | Foodmorrow app, with counts.
```
