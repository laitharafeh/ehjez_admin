import 'package:ehjez_admin/models/admin_court.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:ehjez_admin/services/reservation_service.dart';
import 'package:ehjez_admin/services/strike_service.dart';
import 'package:ehjez_admin/services/customer_service.dart';
import 'package:ehjez_admin/services/promo_service.dart';
import 'package:ehjez_admin/services/pricing_service.dart';
import 'package:ehjez_admin/services/recurring_service.dart';
import 'package:ehjez_admin/services/tournament_service.dart';
import 'package:ehjez_admin/services/staff_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Language ─────────────────────────────────────────────────────────────────

final languageProvider = StateProvider<String>((ref) => 'en');

// ─── Auth ──────────────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.whenData((state) => state.session?.user).value;
});

// ─── Current court ─────────────────────────────────────────────────────────────
//
// Fetched once per session. Every screen that needs courtId / courtName
// reads this provider instead of making its own Supabase call.
// Automatically re-runs when the user changes (login / logout).

final currentCourtProvider = FutureProvider<AdminCourt>((ref) async {
  // Watch the auth stream purely for reactivity — re-runs on login/logout.
  // Do NOT derive the user from it: the stream may not have emitted the new
  // state yet by the time the router redirect lands on HomeScreen, which
  // causes a null-user race and the screen to appear stuck.
  ref.watch(authStateProvider);

  // Read the user directly from the live session — always up-to-date.
  final user = Supabase.instance.client.auth.currentSession?.user;
  if (user == null) throw Exception('Not authenticated');

  // Fast path: user already has a court_managers row (all repeat logins).
  AdminCourt? court = await CourtService.getCourtForUser(user.id);

  // Slow path: first login — ensure_court_manager hasn't run yet because
  // the OTP screen navigates away immediately without waiting for it.
  if (court == null) {
    await Supabase.instance.client.rpc('ensure_court_manager');
    court = await CourtService.getCourtForUser(user.id);
  }

  if (court == null) {
    throw Exception('This account is not linked to any court');
  }

  return court;
});

// ─── Accounting ────────────────────────────────────────────────────────────────

// Legacy typedef kept so InvoiceGenerator callers compile during transition.
typedef AccountingData = ({
  String courtName,
  double revenue,
  double commission,
});

// ── Monthly accounting (new) ───────────────────────────────────────────────────

typedef DayRevenue = ({int day, double revenue, int bookings});
typedef SizeRevenue = ({String size, double revenue, int bookings});
typedef BookingRow = ({
  String date,
  String startTime,
  String size,
  double price,
  double commission,
  String name,
  String phone,
  int fieldNumber,
});
typedef MonthlyAccountingData = ({
  String courtName,
  double revenue,
  double commission,
  int bookingCount,
  double prevMonthRevenue,
  int prevMonthBookings,
  List<DayRevenue> dailyRevenue,
  List<SizeRevenue> bySize,
  List<BookingRow> bookings,
});

typedef AccountingArgs = ({String courtId, int year, int month});

final monthlyAccountingProvider = FutureProvider.autoDispose
    .family<MonthlyAccountingData, AccountingArgs>((ref, args) async {
  final results = await Future.wait([
    CourtService.getCourtName(args.courtId),
    ReservationService.getMonthlyAccounting(
      args.courtId,
      args.year,
      args.month,
    ),
  ]);
  final courtName = (results[0] as String?) ?? 'Court';
  final raw = results[1] as Map<String, dynamic>;

  List<T> parseList<T>(String key, T Function(Map<String, dynamic>) fn) =>
      ((raw[key] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(fn)
          .toList();

  return (
    courtName: courtName,
    revenue: (raw['revenue'] as num).toDouble(),
    commission: (raw['commission'] as num).toDouble(),
    bookingCount: (raw['booking_count'] as num).toInt(),
    prevMonthRevenue: (raw['prev_month_revenue'] as num).toDouble(),
    prevMonthBookings: (raw['prev_month_bookings'] as num).toInt(),
    dailyRevenue: parseList('daily_revenue', (e) => (
          day: (e['day'] as num).toInt(),
          revenue: (e['revenue'] as num).toDouble(),
          bookings: (e['bookings'] as num).toInt(),
        )),
    bySize: parseList('by_size', (e) => (
          size: e['size'] as String,
          revenue: (e['revenue'] as num).toDouble(),
          bookings: (e['bookings'] as num).toInt(),
        )),
    bookings: parseList('bookings', (e) => (
          date: e['date'] as String,
          startTime: e['start_time'] as String,
          size: e['size'] as String? ?? '',
          price: (e['price'] as num).toDouble(),
          commission: (e['commission'] as num).toDouble(),
          name: e['name'] as String? ?? '',
          phone: e['phone'] as String? ?? '',
          fieldNumber: (e['field_number'] as num).toInt(),
        )),
  );
});

// ─── Today's reservations ──────────────────────────────────────────────────────

final todaysReservationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => ReservationService.getTodaysReservations(courtId),
);

// ─── Court sizes (board sidebar) ───────────────────────────────────────────────
//
// Returns a map of size label → number of fields.

final courtSizesProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, courtId) async {
  final rows = await CourtService.getCourtSizes(courtId);
  return {
    for (final r in rows)
      if (((r['number_of_fields'] as num?)?.toInt() ?? 0) > 0)
        r['size'] as String: (r['number_of_fields'] as num).toInt(),
  };
});

// ─── Board bookings ────────────────────────────────────────────────────────────
//
// Keyed by (courtId, size, date) so changing any of those automatically
// triggers a fresh fetch.

typedef BoardArgs = ({String courtId, String size, String date});

final boardBookingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, BoardArgs>(
  (ref, args) =>
      ReservationService.getBookingsForDate(args.courtId, args.size, args.date),
);

// ─── Vacation days ─────────────────────────────────────────────────────────────
//
// AsyncNotifier so mutations (add/remove/clear) can update state directly
// without a round-trip re-fetch.

class VacationDaysNotifier
    extends FamilyAsyncNotifier<Set<DateTime>, String> {
  static DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<Set<DateTime>> build(String courtId) async {
    final dates = await CourtService.getVacationDays(courtId);
    return dates.map((d) => _norm(DateTime.parse(d))).toSet();
  }

  Future<void> toggleDay(DateTime day, String dateStr) async {
    final current = Set<DateTime>.from(state.valueOrNull ?? {});
    final norm = _norm(day);
    if (current.contains(norm)) {
      await CourtService.removeVacationDay(arg, dateStr);
      state = AsyncData(current..remove(norm));
    } else {
      await CourtService.addVacationDay(arg, dateStr);
      state = AsyncData(current..add(norm));
    }
  }

  Future<void> clearAll() async {
    await CourtService.clearAllVacationDays(arg);
    state = const AsyncData({});
  }
}

final vacationDaysProvider = AsyncNotifierProvider.family<
    VacationDaysNotifier, Set<DateTime>, String>(
  VacationDaysNotifier.new,
);

// ─── Analytics ────────────────────────────────────────────────────────────────
//
// Single RPC call — Postgres computes every metric server-side.

final analyticsProvider = FutureProvider.autoDispose
    .family<AnalyticsData, String>(
  (ref, courtId) => ReservationService.getAnalytics(courtId),
);

// ─── Overlapping reservations ──────────────────────────────────────────────────
//
// Fetches all reservations for a date+size and filters to only those that
// overlap the given time window. Delete invalidates the provider so the list
// refreshes automatically.

typedef OverlapArgs = ({
  String courtId,
  String size,
  String date,
  DateTime slotStart,
  DateTime slotEnd,
});

typedef OverlapEntry = ({
  int id,
  String name,
  String phone,
  DateTime start,
  DateTime end,
  int duration,
});

class OverlappingReservationsNotifier
    extends FamilyAsyncNotifier<List<OverlapEntry>, OverlapArgs> {
  @override
  Future<List<OverlapEntry>> build(OverlapArgs args) async {
    final all = await ReservationService.getReservationsWithUsersForDate(
      args.courtId,
      args.size,
      args.date,
    );
    return _filter(all, args.slotStart, args.slotEnd);
  }

  Future<void> deleteReservation(int id) async {
    await ReservationService.deleteReservation(id);
    ref.invalidateSelf();
  }

  List<OverlapEntry> _filter(
    List<Map<String, dynamic>> all,
    DateTime slotStart,
    DateTime slotEnd,
  ) {
    final result = <OverlapEntry>[];
    for (final r in all) {
      final date = DateTime.parse(r['date'] as String);
      final parts = (r['start_time'] as String).split(':');
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final durationHours = r['duration'] as int;
      final end = start.add(Duration(hours: durationHours));

      if (start.isBefore(slotEnd) && end.isAfter(slotStart)) {
        final userMap = r['users'] as Map<String, dynamic>?;
        result.add((
          id: r['id'] as int,
          name: (userMap?['name'] as String?) ??
              (r['name'] as String? ?? 'Unknown'),
          phone: (userMap?['phone'] as String?) ??
              (r['phone'] as String? ?? 'Unknown'),
          start: start,
          end: end,
          duration: durationHours,
        ));
      }
    }
    return result;
  }
}

final overlappingReservationsProvider = AsyncNotifierProvider.family<
    OverlappingReservationsNotifier,
    List<OverlapEntry>,
    OverlapArgs>(
  OverlappingReservationsNotifier.new,
);

// ─── Strike counts ────────────────────────────────────────────────────────────
//
// Keyed by list of phone numbers. Used by TodayReservations to show
// per-phone strike badges in a single query.

final strikeCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, List<String>>(
  (ref, phones) => StrikeService.getActiveStrikeCounts(phones),
);

// ─── Blacklist ────────────────────────────────────────────────────────────────

class BlacklistNotifier extends AsyncNotifier<List<BlacklistEntry>> {
  @override
  Future<List<BlacklistEntry>> build() => StrikeService.getBlacklist();

  Future<void> unblacklist(String phone) async {
    await StrikeService.unblacklistPhone(phone);
    ref.invalidateSelf();
  }

  Future<void> blacklist(String phone, {String? reason}) async {
    await StrikeService.blacklistPhone(phone, reason: reason);
    ref.invalidateSelf();
  }
}

final blacklistProvider =
    AsyncNotifierProvider<BlacklistNotifier, List<BlacklistEntry>>(
  BlacklistNotifier.new,
);

// ─── Promo Codes ──────────────────────────────────────────────────────────────

final promoCodesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => PromoService.getCodes(courtId),
);

// ─── Pricing Rules ────────────────────────────────────────────────────────────

final pricingRulesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => PricingService.getRules(courtId),
);

// ─── Recurring Reservations ───────────────────────────────────────────────────

final recurringReservationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => RecurringService.getRecurring(courtId),
);

// ─── Customers ────────────────────────────────────────────────────────────────

final customersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => CustomerService.getCustomers(courtId),
);

typedef CustomerHistoryArgs = ({String courtId, String phone});

final customerHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, CustomerHistoryArgs>(
  (ref, args) => CustomerService.getBookingHistory(args.courtId, args.phone),
);

// ─── Tournaments ─────────────────────────────────────────────────────────────

final tournamentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => TournamentService.getTournaments(courtId),
);

final tournamentRegistrantsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, tournamentId) => TournamentService.getRegistrants(tournamentId),
);

// ─── Staff accounts ───────────────────────────────────────────────────────────

final staffProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
  (ref, courtId) => StaffService.getStaff(courtId),
);

// ─── Court settings ───────────────────────────────────────────────────────────
//
// Full court record + size/price rows for the settings screen.
// Invalidated after a successful save so the home screen reflects any
// name change on the next visit.

typedef CourtSettingsData = ({
  AdminCourt court,
  List<Map<String, dynamic>> sizePrices,
});

final courtSettingsProvider = FutureProvider.autoDispose
    .family<CourtSettingsData, String>((ref, courtId) async {
  final results = await Future.wait([
    CourtService.getFullCourt(courtId),
    CourtService.getCourtSizesAndPrices(courtId),
  ]);
  return (
    court: results[0] as AdminCourt,
    sizePrices: results[1] as List<Map<String, dynamic>>,
  );
});
