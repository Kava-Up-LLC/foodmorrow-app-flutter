# DESIGN.md — Foodmorrow · "Fresh Batch"

The look of Foodmorrow. Approved on 2026-11-24. Match it; don't redesign it.

- **Screens to copy:** `design/screens/*.png` (390×844 pt, rendered at 2x). They are the source of truth for layout.
  If this file and a screen disagree, the screen wins — and say so.
- **Live canvas:** https://claude.ai/artifact/9tmgLigYYZ7zRm2fZK9L8A (row "Option 1 — Fresh Batch").
- **Inspiration:** the structure of Foodeli by Delisas (https://dribbble.com/shots/25353964-Foodeli-Food-App) with the
  deep green of the client's reference. We take patterns, not their screens.
- Sample data in the screens (Ana's Kitchen, Sofía Ramos…) is only for the mockups.

## 1. Idea

A food app, not a spreadsheet. Round photos of the food, white cards on a light grey-green background, one green for
everything you can tap, and one deep-green banner that answers the only question that matters: **what do I make
tomorrow?** Big numbers, few words.

## 2. Color

| Token | Hex | Use |
|---|---|---|
| `bg` | `#EFF4F5` | Screen background (every screen). |
| `surface` | `#FFFFFF` | Cards, tab bar, inputs, round buttons. |
| `ink` | `#0D1007` | Main text. |
| `muted` | `#5C6661` | Secondary text, inactive icons. 5.4:1 on `bg`. |
| `line` | `#DDE5E3` | Dividers, outlines of unselected tiles and inactive tab circles. |
| `green` | `#27852C` | **Fills only**: primary buttons, active tab pill, `+` buttons, selected day, switch on, checks. White on it = 4.7:1. |
| `greenText` | `#1F6B24` | **Green text**: links ("See all", "Edit"), big quantities, initials on `greenTint`. 5.6:1 on `greenTint`, 6.5:1 on white. |
| `greenTint` | `#E5F1E6` | Selected tile background, avatar circles, minus button, icon circles. |
| `deep` | `#0F4A33` | The Home banner only. |
| `gold` | `#E0B565` | Text on `deep` only (the banner's date line). 5.4:1. |
| `orange` | `#C34614` | "To make" status text and the no-connection icon. |
| `orangeTint` | `#FBE9E1` | Background of the "To make" chip and the no-connection icon circle. |
| `noteBg` | `#FBF3E4` | Order note card. Icon in `#D19E49`. |
| `skeleton` | `#E2EAE8` | Loading / no-connection placeholders. |

Rule: never green text in `#27852C` (it fails contrast on `bg`); use `greenText`. One shadow for the whole app, on
cards and floating things: `0 6 20 rgba(13,16,7,0.06)`.

## 3. Type

**Plus Jakarta Sans**, bundled in `assets/fonts/` (Regular 400, Medium 500, SemiBold 600, Bold 700, ExtraBold 800;
OFL, license in `assets/fonts/OFL.txt`). Numbers use tabular figures.

| Style | Size / weight | Where |
|---|---|---|
| `display` | 30 / 800, -0.6 letter spacing, 1.15 line height | Welcome title. |
| `bannerNumber` | 26 / 800, 1.15 | "52 things to make". |
| `title` | 24 / 800 | Tab screen titles (Orders, Your menu, Settings). |
| `greeting` | 21 / 800 | Business name on Home. |
| `navTitle` | 19 / 800 | Centered title on pushed screens; section headers ("For tomorrow"). |
| `qtyBig` | 30 / 800, -1 | Quantity on the Home product cards, `greenText`. |
| `body` | 16–17 / 700 | Names in lists and cards. |
| `bodyRegular` | 15–16 / 500 | Paragraphs. |
| `small` | 13–14 / 600 | Subtitles, counts, dates, chips (`muted`). |

Sentence case everywhere. No ALL CAPS labels.

## 4. Shape and spacing

- Screen side padding **20**. Gap between cards **10–12**. Section header: 22 above, 10 below.
- Radius: cards **22**, banner **24**, tiles and inputs **18**, small square buttons **10**, pills fully round.
- Photos are **always circles** (`ClipOval`, `BoxFit.cover`). Sizes: 168 banner, 170 add-item preview, 96 menu,
  78 Home card, 52 new-order rows, 48 pickup/detail rows, 30 inside order cards, 66 photo picker.
- Tap targets **≥ 44×44**. The stepper buttons are 32 visible but get a 44 hit area.
- Content scrolls under the floating tab bar; leave 110 of bottom padding so the last item is never hidden.

## 5. Components

| Component | Spec |
|---|---|
| **Tab bar** | Floating white pill: left/right 16, bottom 22 (plus safe area), height 68, radius 34, shadow. Five slots: **Home · Orders · + · Menu · Settings**. Active tab = green pill 48 high with white icon + label. Inactive = 46 circle, 1.5 `line` border, `muted` icon, label only for screen readers. Middle = 52 green circle with white `+` → New order. |
| **Round icon button** | 44 white circle with shadow (back, search, delete). |
| **Primary button** | Full width minus 20+20, height 56, green, white 17/700. Fixed at the bottom of pushed screens (bottom 26–28 + safe area). Can carry a detail after a dot: "Save order · Wed 25". |
| **Secondary button** | Same shape, white with 1.5 green border, `greenText` label. |
| **Small pill button** | Height 34–48, green, white 13–15/700 ("See full list", "New order", "Retry"). |
| **Stepper** | `−` 32 square radius 10 on `greenTint` with green icon (grey `#EDF1F0` with `#A9B4B1` icon and disabled at 0) · number 17/800 · `+` 32 square green with white icon. |
| **Radio tile** | Row of equal tiles, height 88 (pickup day). Unselected: white, 1.5 `line`. Selected: `greenTint`, 2 green border, filled radio. Exposed as a radio group. |
| **Product card (Home)** | 150 wide white card, centered: name 15/800, "3 orders" `muted`, 78 photo, `qtyBig` + "to make". Horizontal scroll, the third card peeks. |
| **Menu card** | 2-column grid, white card: 96 photo, name 15/800, "In 3 orders". No photo → dashed circle with camera, subtitle "Add a photo". |
| **Order card** | White card: 40 initial avatar (`greenTint` / `greenText`), name 16/800, "13 items" `muted` (+ "· has a note"), status chip, chevron. Divider, then items as 30 photo + "12 Cookies". |
| **Status chip** | Height 28, pill. "To make": `orangeTint` / `orange`. "Picked up": `greenTint` / `greenText` with a check. |
| **Pickup row** | 44 photo, name 16/700, items 13 `muted`, 40 round check button: grey outline = waiting, green filled with white check = picked up (name struck through, `muted`). |
| **Day strip** | 7 equal white tiles, height 72, radius 18: weekday 12/600 `muted`, day number 18/800, up to 3 dots for orders. Selected = green with white text and dots. |
| **Banner (Home)** | `deep`, height 150, radius 24. Gold date line, 26/800 white two-line number, green small pill. A 168 food photo bleeds off the right edge (the product with the most to make). |
| **Timeline** | Rows: 20 dot (done = green with check, now = green ring with dot, next = grey ring), label, date on the right. |
| **Input** | White, radius 18, height 56, shadow, leading icon in `muted`. Focused = 2 green border. |
| **Alert banner** | White card with a 40 tinted icon circle, title + subtitle, pill action on the right. Used for No connection. |

Icons: Material Symbols **Rounded** look from the built-in `Icons.*_rounded`: home, calendar_month, add, restaurant,
settings, arrow_back_ios_new, search, delete, check, remove, person, sticky_note_2, photo_camera, shopping_bag,
wifi_off, chevron_right. Size 20–22.

## 6. Screens

| # | File | Screen | Key points |
|---|---|---|---|
| 1 | `01_welcome.png` | Welcome (first open) | Food photo collage, "Know today what you cook tomorrow", body copy, **Add what you sell** → New item. |
| 2 | `02_home.png` | Home | Date + business name · banner "Tomorrow · Wed, Nov 25 / 52 things to make / See full list" · "For tomorrow" product cards + See all · "Pickups today" with "1 of 2 done". |
| 3 | `03_home_empty.png` | Home, nothing tomorrow | White card: bag icon, "No orders for tomorrow yet", copy, **New order**. "Pickups today · None". |
| 4 | `04_new_order.png` | New order / Edit order | Back · customer input · Pickup radio tiles (Today / **Tomorrow** / Pick a day) · "What they want" with steppers and the running item count · note · **Save order · Wed 25**. |
| 5 | `05_orders.png` | Orders | Month + title + search · day strip · "Wednesday · Tomorrow   3 orders" · order cards. |
| 6 | `06_order_detail.png` | Order details | Back · title · delete · customer card with Edit, green **Pickup** strip, items with ×qty · note card · timeline · **Mark as picked up**. |
| 7 | `07_menu.png` | Your menu | Count + title + green square `+` · 2-column menu cards. |
| 8 | `08_add_item.png` | New item / Edit item | Back · big photo preview · Name input · Photo row (4 circles, selected = green ring + check) + "More photos" · **Add to menu** (edit: **Save**). |
| 9 | `09_settings.png` | Settings | Business card with Edit · Week starts on · Time zone · Help · Version · cloud note. |
| 10 | `10_no_connection.png` | No connection | Alert banner with **Retry** on top of skeletons. Same banner on every screen. |

## 7. Motion and feel

- Stepper and pickup check: light haptic (`HapticFeedback.selectionClick`).
- Marking picked up: the check fills and the name strikes through (200 ms). Nothing else animates by itself.
- Lists load with skeletons in `skeleton`, never a full-screen spinner.

## 8. Copy

Short, plain, English. Buttons say what happens: "Save order", "Add to menu", "Mark as picked up". The same action
keeps its name everywhere (after saving, the snackbar says "Order saved"). Errors say what happened and what to do:
"No connection · Your orders are saved. · Retry". Never "server".
