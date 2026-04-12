import 'package:supabase_flutter/supabase_flutter.dart';

class StaffService {
  static final _client = Supabase.instance.client;

  // ─── Read ──────────────────────────────────────────────────────────────────

  /// Returns all staff for [courtId] as a flat list.
  ///
  /// Accepted members (have logged in): { 'user_id', 'role', 'name', 'phone' }
  /// Invited members (not yet logged in): { 'invite_id', 'role', 'name', 'phone' }
  ///
  /// Use presence of 'user_id' vs 'invite_id' to determine which remove call to make.
  static Future<List<Map<String, dynamic>>> getStaff(String courtId) async {
    final result = <Map<String, dynamic>>[];

    // Accepted: non-owner rows in court_managers
    final managersRaw = await _client
        .from('court_managers')
        .select('user_id, role')
        .eq('court_id', courtId)
        .neq('role', 'owner');

    final acceptedPhones = <String>{};
    for (final m in List<Map<String, dynamic>>.from(managersRaw as List)) {
      final userId = m['user_id'] as String;
      final profile = await _client
          .from('users')
          .select('name, phone')
          .eq('id', userId)
          .maybeSingle();
      final phone = (profile?['phone'] as String?) ?? '';
      acceptedPhones.add(phone);
      result.add({
        'user_id': userId,
        'role': m['role'] as String? ?? 'staff',
        'name': (profile?['name'] as String?) ?? '',
        'phone': phone,
      });
    }

    // Invited: rows in court_staff_invites whose phone hasn't logged in yet
    final invitesRaw = await _client
        .from('court_staff_invites')
        .select('id, phone, name, role')
        .eq('court_id', courtId);

    for (final e in (invitesRaw as List)) {
      final m = Map<String, dynamic>.from(e as Map);
      if (!acceptedPhones.contains(m['phone'] as String? ?? '')) {
        result.add({
          'invite_id': m['id'],
          'role': m['role'] as String? ?? 'staff',
          'name': (m['name'] as String?) ?? '',
          'phone': (m['phone'] as String?) ?? '',
        });
      }
    }

    return result;
  }

  // ─── Invite ────────────────────────────────────────────────────────────────

  /// Creates a staff invite for [phone]. When the person logs in via OTP for
  /// the first time, [ensure_court_manager] automatically accepts the invite
  /// and creates a court_managers row.
  static Future<void> inviteStaff({
    required String courtId,
    required String phone,
    required String name,
    required String role, // 'staff' | 'coach'
  }) async {
    await _client.from('court_staff_invites').insert({
      'court_id': courtId,
      'phone': phone,
      'name': name,
      'role': role,
    });
  }

  // ─── Remove ────────────────────────────────────────────────────────────────

  /// Removes an accepted staff member via the SECURITY DEFINER RPC.
  static Future<void> removeStaff(String courtId, String userId) async {
    await _client.rpc('remove_staff_member', params: {
      'p_court_id': courtId,
      'p_user_id': userId,
    });
  }

  /// Revokes a pending invite row by [inviteId].
  static Future<void> revokeInvite(int inviteId) async {
    await _client
        .from('court_staff_invites')
        .delete()
        .eq('id', inviteId);
  }
}
