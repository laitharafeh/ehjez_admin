import 'package:supabase_flutter/supabase_flutter.dart';

class PricingService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getRules(String courtId) async {
    final rows = await _client
        .from('pricing_rules')
        .select()
        .eq('court_id', courtId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> createRule({
    required String courtId,
    required String size,
    required String label,
    List<int>? daysOfWeek,
    String? specificDate,
    required double price1,
    required double price2,
  }) async {
    await _client.from('pricing_rules').insert({
      'court_id': courtId,
      'size': size,
      'label': label,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (specificDate != null) 'specific_date': specificDate,
      'price1': price1,
      'price2': price2,
    });
  }

  static Future<void> deleteRule(int id) async {
    await _client.from('pricing_rules').delete().eq('id', id);
  }

  /// Returns effective {price1, price2, rule_label} for a date+size combo.
  /// Returns null if no rule applies (use base price).
  static Future<Map<String, dynamic>?> getEffectivePrice(
      String courtId, String size, String date) async {
    final rows = await _client.rpc('get_effective_price', params: {
      'p_court_id': courtId,
      'p_size': size,
      'p_date': date,
    });
    final list = List<Map<String, dynamic>>.from(rows as List);
    return list.isEmpty ? null : list.first;
  }
}
