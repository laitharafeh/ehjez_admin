import 'package:supabase_flutter/supabase_flutter.dart';

typedef StrikeEntry = ({
  int id,
  String phone,
  DateTime createdAt,
  int? reservationId,
});

typedef BlacklistEntry = ({
  String phone,
  DateTime blacklistedAt,
  String reason,
});

class StrikeService {
  static final _client = Supabase.instance.client;

  // ─── Strikes ──────────────────────────────────────────────────────────────

  /// Adds a no-show strike for [phone]. Returns the new active strike count.
  static Future<int> addStrike({
    required String phone,
    required String courtId,
    int? reservationId,
  }) async {
    await _client.from('strikes').insert({
      'phone': phone,
      'court_id': courtId,
      if (reservationId != null) 'reservation_id': reservationId,
    });
    return getActiveStrikeCount(phone);
  }

  /// Returns how many strikes [phone] has in the last 6 months.
  static Future<int> getActiveStrikeCount(String phone) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final response = await _client
        .from('strikes')
        .select('id')
        .eq('phone', phone)
        .gte('created_at', cutoff.toIso8601String());
    return (response as List).length;
  }

  /// Returns active strike counts for a list of phone numbers in one query.
  /// Returns a map of phone → active strike count.
  static Future<Map<String, int>> getActiveStrikeCounts(
    List<String> phones,
  ) async {
    if (phones.isEmpty) return {};
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final response = await _client
        .from('strikes')
        .select('phone')
        .inFilter('phone', phones)
        .gte('created_at', cutoff.toIso8601String());
    final counts = <String, int>{};
    for (final row in response as List) {
      final p = row['phone'] as String;
      counts[p] = (counts[p] ?? 0) + 1;
    }
    return counts;
  }

  /// Removes a single strike by its [strikeId].
  static Future<void> removeStrike(int strikeId) async {
    await _client.from('strikes').delete().eq('id', strikeId);
  }

  // ─── Blacklist ────────────────────────────────────────────────────────────

  /// Returns all currently blacklisted phones.
  static Future<List<BlacklistEntry>> getBlacklist() async {
    final response = await _client
        .from('blacklisted_phones')
        .select('phone, blacklisted_at, reason')
        .order('blacklisted_at', ascending: false);
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map((e) => (
              phone: e['phone'] as String,
              blacklistedAt: DateTime.parse(e['blacklisted_at'] as String),
              reason: e['reason'] as String,
            ))
        .toList();
  }

  /// Returns true if [phone] is blacklisted.
  static Future<bool> isBlacklisted(String phone) async {
    final response = await _client
        .from('blacklisted_phones')
        .select('phone')
        .eq('phone', phone)
        .maybeSingle();
    return response != null;
  }

  /// Manually blacklists a phone number.
  static Future<void> blacklistPhone(String phone, {String? reason}) async {
    await _client.from('blacklisted_phones').upsert({
      'phone': phone,
      if (reason != null) 'reason': reason,
    });
  }

  /// Removes a phone from the blacklist (unban).
  static Future<void> unblacklistPhone(String phone) async {
    await _client.from('blacklisted_phones').delete().eq('phone', phone);
  }
}
