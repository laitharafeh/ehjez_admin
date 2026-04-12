import 'dart:typed_data';

import 'package:ehjez_admin/models/admin_court.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourtService {
  static final _client = Supabase.instance.client;

  // ─── Court ──────────────────────────────────────────────────────────────────

  static const _courtColumns =
      'id, name, phone, location, category, start_time, end_time, '
      'working_days, image_url, image2_url, image3_url';

  /// Fetches the court linked to [phone], or null if none found.
  /// Kept for the login gate check (courtExistsForPhone).
  static Future<AdminCourt?> getCourtByPhone(String phone) async {
    final response = await _client
        .from('courts')
        .select(_courtColumns)
        .eq('phone', phone)
        .maybeSingle();
    return response != null ? AdminCourt.fromMap(response) : null;
  }

  /// Fetches the court for the authenticated [userId] via court_managers.
  /// Returns null if the user has no linked court.
  /// The returned [AdminCourt.role] reflects the user's role (owner/staff/coach).
  static Future<AdminCourt?> getCourtForUser(String userId) async {
    final cm = await _client
        .from('court_managers')
        .select('court_id, role')
        .eq('user_id', userId)
        .maybeSingle();
    if (cm == null) return null;
    final court = await getFullCourt(cm['court_id'] as String);
    return court.copyWith(role: cm['role'] as String? ?? 'owner');
  }

  /// Fetches the full court record by [courtId].
  static Future<AdminCourt> getFullCourt(String courtId) async {
    final response = await _client
        .from('courts')
        .select(_courtColumns)
        .eq('id', courtId)
        .single();
    return AdminCourt.fromMap(response);
  }

  /// Updates editable fields on the court row. Only non-null arguments
  /// are included in the PATCH, so partial updates are safe.
  static Future<void> updateCourt(
    String courtId, {
    String? name,
    String? category,
    String? location,
    String? startTime,
    String? endTime,
    List<int>? workingDays,
    String? imageUrl,
    String? image2Url,
    String? image3Url,
  }) async {
    final patch = <String, dynamic>{
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (workingDays != null) 'working_days': workingDays,
      if (imageUrl != null) 'image_url': imageUrl,
      if (image2Url != null) 'image2_url': image2Url,
      if (image3Url != null) 'image3_url': image3Url,
    };
    if (patch.isEmpty) return;
    await _client.from('courts').update(patch).eq('id', courtId);
  }

  /// Adds a new size row for [courtId]. Throws if the size name already exists.
  static Future<void> addSizePrice(
    String courtId, {
    required String size,
    double? price1,
    double? price2,
    required int numberOfFields,
  }) async {
    await _client.from('courts_size_price').insert({
      'court_id': courtId,
      'size': size,
      if (price1 != null) 'price1': price1,
      if (price2 != null) 'price2': price2,
      'number_of_fields': numberOfFields,
    });
  }

  /// Returns the count of upcoming (today onwards) reservations for [size].
  static Future<int> getUpcomingReservationCountForSize(
    String courtId,
    String size,
  ) async {
    final result = await _client.rpc(
      'get_upcoming_reservations_count_for_size',
      params: {'p_court_id': courtId, 'p_size': size},
    );
    return (result as num).toInt();
  }

  /// Deletes the courts_size_price row with [rowId].
  static Future<void> deleteSizePrice(int rowId) async {
    await _client.from('courts_size_price').delete().eq('id', rowId);
  }

  /// Updates a single courts_size_price row identified by [rowId].
  static Future<void> updateSizePrice(
    int rowId, {
    double? price1,
    double? price2,
    int? numberOfFields,
  }) async {
    final patch = <String, dynamic>{
      if (price1 != null) 'price1': price1,
      if (price2 != null) 'price2': price2,
      if (numberOfFields != null) 'number_of_fields': numberOfFields,
    };
    if (patch.isEmpty) return;
    await _client.from('courts_size_price').update(patch).eq('id', rowId);
  }

  /// Uploads [bytes] to the court-images bucket under
  /// `{courtId}/image{slot}.{ext}` (upserts on repeat upload).
  /// Returns the public URL of the uploaded image.
  static Future<String> uploadCourtImage(
    String courtId,
    int slot,
    Uint8List bytes,
    String ext,
  ) async {
    final path = '$courtId/image$slot.$ext';
    await _client.storage.from('court-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('court-images').getPublicUrl(path);
  }

  /// Fetches just the display name for [courtId].
  static Future<String?> getCourtName(String courtId) async {
    final response = await _client
        .from('courts')
        .select('name')
        .eq('id', courtId)
        .single();
    return response['name'] as String?;
  }

  /// Fetches `start_time` and `end_time` for [courtId].
  static Future<Map<String, dynamic>> getCourtTimings(String courtId) async {
    return await _client
        .from('courts')
        .select('start_time, end_time')
        .eq('id', courtId)
        .single();
  }

  // ─── Sizes & Prices ─────────────────────────────────────────────────────────

  /// Returns size rows with `id`, `size`, `number_of_fields`, `price1`, `price2`.
  static Future<List<Map<String, dynamic>>> getCourtSizesAndPrices(
    String courtId,
  ) async {
    final response = await _client
        .from('courts_size_price')
        .select('id, size, number_of_fields, price1, price2')
        .eq('court_id', courtId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Returns size rows with only `size` and `number_of_fields`.
  static Future<List<Map<String, dynamic>>> getCourtSizes(
    String courtId,
  ) async {
    final response = await _client
        .from('courts_size_price')
        .select('size, number_of_fields')
        .eq('court_id', courtId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ─── Vacation Days ───────────────────────────────────────────────────────────

  /// Returns all vacation day date strings for [courtId].
  static Future<List<String>> getVacationDays(String courtId) async {
    final response = await _client
        .from('court_vacation_days')
        .select('vacation_date')
        .eq('court_id', courtId);
    return (response as List)
        .map((r) => r['vacation_date'] as String)
        .toList();
  }

  /// Returns only upcoming (today onwards) vacation day date strings.
  static Future<List<String>> getUpcomingVacationDays(String courtId) async {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('court_vacation_days')
        .select('vacation_date')
        .eq('court_id', courtId)
        .gte('vacation_date', todayStr);
    return (response as List)
        .map((r) => r['vacation_date'] as String)
        .toList();
  }

  /// Marks [dateStr] (yyyy-MM-dd) as a vacation day for [courtId].
  static Future<void> addVacationDay(String courtId, String dateStr) async {
    await _client.from('court_vacation_days').insert({
      'court_id': courtId,
      'vacation_date': dateStr,
    });
  }

  /// Removes the vacation day on [dateStr] for [courtId].
  static Future<void> removeVacationDay(
    String courtId,
    String dateStr,
  ) async {
    await _client
        .from('court_vacation_days')
        .delete()
        .eq('court_id', courtId)
        .eq('vacation_date', dateStr);
  }

  /// Removes all vacation days for [courtId].
  static Future<void> clearAllVacationDays(String courtId) async {
    await _client
        .from('court_vacation_days')
        .delete()
        .eq('court_id', courtId);
  }
}
