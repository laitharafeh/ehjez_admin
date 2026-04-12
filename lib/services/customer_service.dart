import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  static final _client = Supabase.instance.client;

  /// Returns aggregated customer rows for the given court.
  /// Each row: phone, name, booking_count, total_spend, last_booking, first_booking
  static Future<List<Map<String, dynamic>>> getCustomers(
      String courtId) async {
    final rows = await _client.rpc(
      'get_court_customers',
      params: {'p_court_id': courtId},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Returns past reservations for [phone] at [courtId], newest first.
  static Future<List<Map<String, dynamic>>> getBookingHistory(
      String courtId, String phone) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from('reservations')
        .select('id, date, start_time, duration, size, price, field_number, name')
        .eq('court_id', courtId)
        .eq('phone', phone)
        .lte('date', todayStr)
        .order('date', ascending: false)
        .order('start_time', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
