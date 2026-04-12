import 'package:supabase_flutter/supabase_flutter.dart';

class PromoService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getCodes(String courtId) async {
    final rows = await _client
        .from('promo_codes')
        .select()
        .eq('court_id', courtId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> createCode({
    required String courtId,
    required String code,
    required String type, // 'percent' | 'fixed'
    required double value,
    int? maxUses,
    String? validFrom,
    String? validUntil,
  }) async {
    await _client.from('promo_codes').insert({
      'court_id': courtId,
      'code': code.trim().toUpperCase(),
      'type': type,
      'value': value,
      if (maxUses != null) 'max_uses': maxUses,
      if (validFrom != null) 'valid_from': validFrom,
      if (validUntil != null) 'valid_until': validUntil,
    });
  }

  static Future<void> toggleActive(int id, bool isActive) async {
    await _client
        .from('promo_codes')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  static Future<void> deleteCode(int id) async {
    await _client.from('promo_codes').delete().eq('id', id);
  }
}
