import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Analytics types ──────────────────────────────────────────────────────────
// Defined here so the service owns the shape of the data it returns.

typedef MonthlyRevenue = ({String month, double revenue, int bookings});
typedef PeakHour = ({int hour, int count});
typedef WeekdayStats = ({
  int dayNum,
  String dayLabel,
  int bookings,
  double revenue,
});
typedef SizeStats = ({String size, int count});
typedef AnalyticsSummary = ({
  int totalBookings,
  double totalRevenue,
  double totalCommission,
  double avgBookingValue,
  int monthBookings,
  double monthRevenue,
});
typedef AnalyticsData = ({
  List<MonthlyRevenue> monthlyRevenue,
  List<PeakHour> peakHours,
  List<WeekdayStats> byWeekday,
  List<SizeStats> bySize,
  AnalyticsSummary summary,
});

class ReservationService {
  static final _client = Supabase.instance.client;

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Board ───────────────────────────────────────────────────────────────────

  /// Fetches bookings for a specific [courtId], [size], and [date] (yyyy-MM-dd).
  /// Returns fields needed by the court assignment board.
  static Future<List<Map<String, dynamic>>> getBookingsForDate(
    String courtId,
    String size,
    String date,
  ) async {
    final response = await _client
        .from('reservations')
        .select('id, start_time, duration, size, field_number, name, phone')
        .eq('court_id', courtId)
        .eq('size', size)
        .eq('date', date)
        .order('field_number')
        .order('start_time');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Deletes a reservation by its [id].
  static Future<void> deleteReservation(int id) async {
    await _client.from('reservations').delete().eq('id', id);
  }

  // ─── Calendar ────────────────────────────────────────────────────────────────

  /// Fetches all upcoming reservations (today onwards) for [courtId] + [size].
  static Future<List<Map<String, dynamic>>> getUpcomingReservations(
    String courtId,
    String size,
  ) async {
    final response = await _client
        .from('reservations')
        .select()
        .eq('court_id', courtId)
        .eq('size', size)
        .gte('date', _dateString(DateTime.now()))
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Calls the `book_slot` RPC and returns the result map.
  static Future<Map<String, dynamic>> bookSlot({
    required String courtId,
    required String date,
    required String startTime,
    required int duration,
    required String size,
    required String name,
    required String phone,
    required int price,
  }) async {
    return await _client.rpc('book_slot', params: {
      'p_court_id': courtId,
      'p_date': date,
      'p_start_time': startTime,
      'p_duration': duration,
      'p_size': size,
      'p_name': name,
      'p_phone': phone,
      'p_price': price,
    });
  }

  // ─── Overlapping page ────────────────────────────────────────────────────────

  /// Fetches all reservations (with joined user details) for [courtId], [size],
  /// and [date]. The caller is responsible for filtering overlaps.
  static Future<List<Map<String, dynamic>>> getReservationsWithUsersForDate(
    String courtId,
    String size,
    String date,
  ) async {
    final response = await _client
        .from('reservations')
        .select('*, users!user_id(name, phone)')
        .eq('court_id', courtId)
        .eq('size', size)
        .eq('date', date)
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ─── Today's reservations widget ─────────────────────────────────────────────

  /// Fetches today's reservations for [courtId].
  static Future<List<Map<String, dynamic>>> getTodaysReservations(
    String courtId,
  ) async {
    final response = await _client
        .from('reservations')
        .select('id, start_time, duration, size, phone, name, field_number')
        .eq('court_id', courtId)
        .eq('date', _dateString(DateTime.now()))
        .order('start_time', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ─── Accounting ──────────────────────────────────────────────────────────────

  /// Sums all commission values across all time for [courtId].
  static Future<double> getTotalCommission(String courtId) async {
    final response = await _client
        .from('reservations')
        .select('commission')
        .eq('court_id', courtId);
    double total = 0.0;
    for (final row in response as List) {
      final c = row['commission'];
      if (c != null) total += (c as num).toDouble();
    }
    return total;
  }

  /// Sums all reservation prices for [courtId] within the given [month].
  static Future<double> getMonthlyRevenue(
    String courtId,
    DateTime month,
  ) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final response = await _client
        .from('reservations')
        .select('price')
        .eq('court_id', courtId)
        .gte('date', _dateString(firstDay))
        .lte('date', _dateString(lastDay));
    double total = 0.0;
    for (final row in response as List) {
      final price = row['price'];
      if (price != null) total += (price as num).toDouble();
    }
    return total;
  }

  /// Calls the get_court_monthly_accounting RPC and returns the raw JSON map.
  static Future<Map<String, dynamic>> getMonthlyAccounting(
    String courtId,
    int year,
    int month,
  ) async {
    final response = await _client.rpc(
      'get_court_monthly_accounting',
      params: {
        'p_court_id': courtId,
        'p_year': year,
        'p_month': month,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────

  /// Fetches all analytics for [courtId] in a single RPC call.
  /// [months] controls how far back the monthly-revenue series goes.
  static Future<AnalyticsData> getAnalytics(
    String courtId, {
    int months = 6,
  }) async {
    final raw = await _client.rpc('get_court_analytics', params: {
      'p_court_id': courtId,
      'p_months': months,
    }) as Map<String, dynamic>;

    final monthlyRevenue = (raw['monthly_revenue'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((e) => (
              month: e['month'] as String,
              revenue: (e['revenue'] as num).toDouble(),
              bookings: e['bookings'] as int,
            ))
        .toList();

    final peakHours = (raw['peak_hours'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((e) => (
              hour: e['hour'] as int,
              count: e['count'] as int,
            ))
        .toList();

    final byWeekday = (raw['by_weekday'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((e) => (
              dayNum: e['day_num'] as int,
              dayLabel: e['day_label'] as String,
              bookings: e['bookings'] as int,
              revenue: (e['revenue'] as num).toDouble(),
            ))
        .toList();

    final bySize = (raw['by_size'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((e) => (
              size: e['size'] as String,
              count: e['count'] as int,
            ))
        .toList();

    final s = (raw['summary'] as Map<String, dynamic>?) ?? {};
    final summary = (
      totalBookings: (s['total_bookings'] as int?) ?? 0,
      totalRevenue: ((s['total_revenue'] as num?) ?? 0).toDouble(),
      totalCommission: ((s['total_commission'] as num?) ?? 0).toDouble(),
      avgBookingValue: ((s['avg_booking_value'] as num?) ?? 0).toDouble(),
      monthBookings: (s['month_bookings'] as int?) ?? 0,
      monthRevenue: ((s['month_revenue'] as num?) ?? 0).toDouble(),
    );

    return (
      monthlyRevenue: monthlyRevenue,
      peakHours: peakHours,
      byWeekday: byWeekday,
      bySize: bySize,
      summary: summary,
    );
  }
}
