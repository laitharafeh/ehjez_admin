import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getRecurring(
      String courtId) async {
    final rows = await _client
        .from('recurring_reservations')
        .select()
        .eq('court_id', courtId)
        .order('day_of_week')
        .order('start_time');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Creates a recurring template and materialises it for the next [weeks] weeks.
  /// Returns the number of reservation rows inserted.
  static Future<int> createRecurring({
    required String courtId,
    required String name,
    required String phone,
    required String size,
    required int fieldNumber,
    required String startTime, // HH:MM
    required int duration,
    required int dayOfWeek,
    required double price,
    required String startDate, // yyyy-MM-dd
    String? endDate,
    int weeks = 12,
  }) async {
    final inserted = await _client.from('recurring_reservations').insert({
      'court_id': courtId,
      'name': name,
      'phone': phone,
      'size': size,
      'field_number': fieldNumber,
      'start_time': startTime,
      'duration': duration,
      'day_of_week': dayOfWeek,
      'price': price,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    }).select('id').single();

    final id = inserted['id'] as int;

    final count = await _client.rpc('materialise_recurring', params: {
      'p_recurring_id': id,
      'p_weeks': weeks,
    });
    return (count as num).toInt();
  }

  static Future<void> deleteRecurring(int id) async {
    await _client.from('recurring_reservations').delete().eq('id', id);
  }
}
