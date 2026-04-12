import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentService {
  static final _client = Supabase.instance.client;

  /// Fetch all tournaments for a given court, newest first.
  /// Includes a count of registrations for each tournament.
  static Future<List<Map<String, dynamic>>> getTournaments(
      String courtId) async {
    final rows = await _client
        .from('tournaments')
        .select('*, tournament_registrations(count)')
        .eq('court_id', courtId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Create a new tournament.
  static Future<void> createTournament({
    required String courtId,
    required String title,
    required String description,
    required String date,
    required String time,
    required int maxParticipants,
    required int entryFee,
    required String prize,
    required bool isActive,
  }) async {
    await _client.from('tournaments').insert({
      'court_id': courtId,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'max_participants': maxParticipants,
      'entry_fee': entryFee,
      'prize': prize,
      'is_active': isActive,
    });
  }

  /// Fetch all registrants for a given tournament.
  static Future<List<Map<String, dynamic>>> getRegistrants(
      String tournamentId) async {
    final rows = await _client
        .from('tournament_registrations')
        .select('name, phone')
        .eq('tournament_id', tournamentId)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }
}
