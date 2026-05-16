# ehjez_admin — Session Handoff

This document captures the full state of the project as of the end of the session so a new Claude instance can pick up without needing the old conversation history.

---

## 1. What This Project Is

**ehjez_admin** is a Flutter **web** app (admin panel) for court managers. It is hosted on **Cloudflare Pages** and backed by **Supabase** (auth + database). Court owners use it to manage reservations, staff, pricing, analytics, tournaments, and promo codes. Staff/coaches get a limited view of the same panel.

- **Project path:** `/Users/laitharafeh/flutter_projects/ehjez_admin`
- **Supabase project ID:** `bjijwzpkctdodimnlhxk`
- **Supabase URL:** `https://bjijwzpkctdodimnlhxk.supabase.co`
- **Supabase anon key:** stored in `lib/keys.dart` (gitignored — generated at build time from Cloudflare env vars)

---

## 2. Tech Stack

| Layer | Choice |
|---|---|
| UI framework | Flutter web |
| State management | Riverpod (flutter_riverpod) |
| Routing | go_router |
| Backend | Supabase (Postgres + Auth + Storage) |
| Hosting | Cloudflare Pages |
| Auth method | OTP via phone (Supabase) |
| Fonts | Google Fonts (Grandstander for logo, Calibri for UI) |

---

## 3. Key Files and Their Current State

### `lib/keys.dart` (gitignored)
Generated at build time. Contains:
```dart
const String supabaseUrl = 'https://bjijwzpkctdodimnlhxk.supabase.co';
const String supabaseAnonKey = '<key>';
```
The build script (`build_cf.sh`) writes this file from Cloudflare environment variables `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

---

### `lib/main.dart`
```dart
void main() async {
  usePathUrlStrategy();          // ← important: clean URLs (no hash)
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: MyApp()));
}
```
`usePathUrlStrategy()` is required for Cloudflare Pages. Without it, deep-link refreshes 404.

---

### `lib/router/app_router.dart` — THE MOST IMPORTANT FILE

The router uses a custom `_AuthChangeNotifier` as `refreshListenable`. **Critical rule:**

```dart
_sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  // ONLY fire on real login/logout. TOKEN_REFRESHED, INITIAL_SESSION,
  // USER_UPDATED etc. must NOT call notifyListeners() — they cause
  // go_router to redirect while already mid-navigation → stuck screen.
  if (data.event == AuthChangeEvent.signedIn ||
      data.event == AuthChangeEvent.signedOut) {
    notifyListeners();
  }
});
```

This filtering was the root fix for the "login/logout gets stuck" bug. Do not remove it.

---

### `lib/screens/auth/otp_screen.dart`

After verifying the OTP, the screen does **NOT** call `context.go('/')`. The comment explains why:
```dart
// Navigation is handled entirely by go_router's refreshListenable.
// The SIGNED_IN auth event fires synchronously inside verifyOTP, which
// triggers _AuthChangeNotifier → notifyListeners() → redirect to '/'.
// Calling context.go('/') here as well creates a double-navigation race
// that leaves go_router stuck between routes.
```

---

### `lib/providers/providers.dart`

`currentCourtProvider` — **do not add an intermediate userId provider back**:
```dart
final currentCourtProvider = FutureProvider<AdminCourt>((ref) async {
  ref.watch(authStateProvider);  // for reactivity only
  // Read user directly from the live session — NOT from the stream value.
  // The stream may not have emitted yet when the router redirect lands on HomeScreen.
  final user = Supabase.instance.client.auth.currentSession?.user;
  if (user == null) throw Exception('Not authenticated');
  AdminCourt? court = await CourtService.getCourtForUser(user.id);
  if (court == null) {
    await Supabase.instance.client.rpc('ensure_court_manager');
    court = await CourtService.getCourtForUser(user.id);
  }
  if (court == null) throw Exception('This account is not linked to any court');
  return court;
});
```

`staffProvider` returns a flat `List<Map<String, dynamic>>` (no typedef, no separate invited/accepted lists):
```dart
final staffProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => StaffService.getStaff(courtId),
);
```

---

### `lib/services/staff_service.dart`

`getStaff()` returns a flat list. Each item has **either** `user_id` (accepted, has logged in) or `invite_id` (still pending first login). No "pending" label is shown in the UI — the distinction only matters for which delete method to call:

```dart
// Accepted member: { 'user_id', 'role', 'name', 'phone' }
// Pending invite:  { 'invite_id', 'role', 'name', 'phone' }
```

Stale invites (where the coach already logged in but the invite row wasn't cleaned up) are filtered out client-side: `getStaff` checks accepted phones from `court_managers` and excludes any invite rows whose phone is already in that set.

---

### `lib/screens/court_settings_screen.dart`

Staff removal uses a single `_removeEntry` method (no separate `_removeStaff` / `_revokeInvite`):
```dart
Future<void> _removeEntry(Map<String, dynamic> entry) async {
  if (entry['user_id'] != null) {
    await StaffService.removeStaff(widget.courtId, entry['user_id'] as String);
  } else {
    await StaffService.revokeInvite(entry['invite_id'] as int);
  }
}
```

Staff tile has **no status/pending label** — removed entirely.

---

### `lib/screens/home_screen.dart`

`ConsumerWidget` (not StatefulWidget). The settings gear icon is shown only for owners:
```dart
if (courtAsync.valueOrNull?.isOwner == true)
  IconButton(icon: const Icon(Icons.settings_outlined), ...)
```

The home screen's button grid is also role-gated: coaches see only their permitted buttons. `AdminCourt.isOwner` drives visibility. There is **no** `cleanup_my_invite` RPC call anywhere in the Flutter code.

---

### `web/_redirects`
```
/* /index.html 200
```
Required for Cloudflare Pages SPA routing (all paths serve index.html).

---

### `build_cf.sh`
```bash
#!/bin/bash
set -e
# 1. Write keys from CF env vars
cat > lib/keys.dart << EOF
const String supabaseUrl = '${SUPABASE_URL}';
const String supabaseAnonKey = '${SUPABASE_ANON_KEY}';
EOF
# 2. Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"
# 3. Build
flutter config --enable-web
flutter pub get
flutter build web --release
# 4. Output to dist/ (Cloudflare Pages default)
mv build/web dist
echo "Build complete → dist/"
```

---

## 4. Database (Supabase)

### Tables used

| Table | Purpose |
|---|---|
| `users` | User profiles (name, phone) — one row per auth user |
| `courts` | Court records |
| `court_managers` | Links users to courts with a role (`owner`, `staff`, `coach`) |
| `court_staff_invites` | Pending invites — created when owner invites a phone number |
| `reservations` | Booking records |
| `pricing_rules` | Per-court pricing |
| `promo_codes` | Discount codes |
| `tournaments` | Tournament records |
| `tournament_registrants` | Who joined a tournament |
| `recurring_reservations` | Repeating bookings |
| `vacation_days` | Days the court is closed |

### Key RPC functions

- **`ensure_court_manager`** — Called on first login. Checks if the logged-in phone has a `court_staff_invites` row; if yes, creates a `court_managers` row with the invited role. If no invite exists, creates an owner row.
- **`remove_staff_member(p_court_id, p_user_id)`** — SECURITY DEFINER RPC; removes a `court_managers` row. Required because the table has RLS.

### DB trigger

A trigger `cleanup_invite_after_manager_insert` exists on `court_managers`:
```sql
-- Fires AFTER INSERT on court_managers
-- Deletes the matching court_staff_invites row (same court_id + phone)
-- so stale invite rows don't accumulate
```
This was created during this session. It works in combination with the client-side phone-filter in `getStaff()`.

---

## 5. Role-Based Access

`AdminCourt` model has an `isOwner` bool. The home screen and other screens gate features on this:

- **Owner:** sees all buttons (reservations, accounting, analytics, settings gear, vacation days, pricing, recurring, customers, tournaments, promo codes)
- **Staff/Coach:** sees only their permitted subset (3 buttons: reservations, accounting stub, and one other — exact set controlled in `home_screen.dart`'s button grid)

The role comes from `currentCourtProvider` → `CourtService.getCourtForUser()` which reads the `court_managers.role` column for the logged-in user.

---

## 6. Cloudflare Pages Deployment

### Setup steps taken
1. Created a **Pages** project (NOT a Workers project — the UI is confusing)
2. Connected the GitHub repo
3. Set build command: `bash build_cf.sh`
4. Set output directory: `dist`
5. Added environment variables: `SUPABASE_URL` and `SUPABASE_ANON_KEY`

### Pending: add Supabase allowed redirect URLs
Once the Pages domain is known (e.g. `https://ehjez-admin.pages.dev`), go to:
**Supabase dashboard → Authentication → URL Configuration → Redirect URLs**
and add the Pages domain. Without this, OTP logins from the live domain will fail.

Also add the domain to:
**Supabase dashboard → Authentication → URL Configuration → Site URL**

---

## 7. Bugs Fixed This Session (context for future debugging)

### Bug: Login/logout stuck
**Root causes (all three were present simultaneously):**
1. `_AuthChangeNotifier` was calling `notifyListeners()` on `TOKEN_REFRESHED` and `INITIAL_SESSION` events → go_router tried to redirect while already navigating → stuck. **Fix:** filter to only `signedIn`/`signedOut`.
2. `OtpScreen._verify()` was calling `context.go('/')` after successful OTP → double-navigation race with the router redirect. **Fix:** removed the `context.go('/')` call entirely.
3. A `cleanup_my_invite` RPC was being called from `currentCourtProvider` or `HomeScreen` → the async gap between OTP success and the RPC completing left the session in a broken state. **Fix:** removed all client-side invite cleanup; moved it to a DB trigger.

### Bug: Coach sees owner buttons after logging in
**Root cause:** An intermediate `_authUserIdProvider` (a `StreamProvider` using a `last` variable closure) sometimes didn't emit when a different user logged in, so `currentCourtProvider` served the owner's cached court data to the coach.
**Fix:** Deleted `_authUserIdProvider` entirely. `currentCourtProvider` now reads `Supabase.instance.client.auth.currentSession?.user` directly (synchronous, always up-to-date) and uses `authStateProvider` only as a reactive trigger.

### Bug: Pending invite still showing after coach logs in
**Root cause:** `court_staff_invites` rows weren't deleted when the coach logged in and `ensure_court_manager` created the `court_managers` row.
**Fix:**
1. DB trigger `cleanup_invite_after_manager_insert` auto-deletes invite on `court_managers` INSERT.
2. One-time SQL cleanup deleted all stale rows.
3. `getStaff()` client-side phone filter as a belt-and-suspenders fallback.

---

## 8. Sales Presentation

A 4-slide PowerPoint was generated at:
- `/tmp/ehjez_pitch.pptx`
- `~/Desktop/ehjez_pitch.pptx` (copy)

Generated with pptxgenjs (`/tmp/ehjez_deck.js`). Brand color `#068631`. Slides:
1. Title — dark green background, large "ehjez" wordmark
2. "What ehjez Does For You" — 4 feature cards (reservations, finances, customers, tournaments)
3. "Built for Your Team" — 4 feature cards (owner dashboard, staff accounts, promo codes, device-agnostic)
4. "What's Coming Next" — dark green background, 4 items including Odoo ERP integration

---

## 9. Pending / Next Steps

| # | Task | Notes |
|---|---|---|
| 1 | **Add Supabase redirect URLs** for the live Cloudflare domain | Required before live OTP logins work |
| 2 | **Verify Cloudflare build passes** — first deploy may fail if Flutter stable version has issues | Check CF Pages build logs |
| 3 | **Test coach login end-to-end** on the live domain | Verify role gating and no stuck navigation |
| 4 | **Odoo ERP integration** (future feature) | Mentioned in sales deck as "coming soon" |
| 5 | **Customer mobile app** (future feature) | Mentioned in sales deck |

---

## 10. How to Run Locally

```bash
cd /Users/laitharafeh/flutter_projects/ehjez_admin

# keys.dart is gitignored — create it manually for local dev:
cat > lib/keys.dart << 'EOF'
const String supabaseUrl = 'https://bjijwzpkctdodimnlhxk.supabase.co';
const String supabaseAnonKey = '<your-anon-key>';
EOF

flutter pub get
flutter run -d chrome
```

---

## 11. Things NOT to Change

These are fragile and were fixed after hard debugging — do not revert:

1. **Do not add `context.go('/')` back to `OtpScreen._verify()`**
2. **Do not fire `notifyListeners()` on `TOKEN_REFRESHED` or `INITIAL_SESSION` in `_AuthChangeNotifier`**
3. **Do not re-introduce `_authUserIdProvider`** — it caused the coach role bug
4. **Do not call any Supabase RPC from `currentCourtProvider`** other than `ensure_court_manager` (which is already there)
5. **Do not call `cleanup_my_invite` or equivalent from Flutter** — that is handled by the DB trigger
