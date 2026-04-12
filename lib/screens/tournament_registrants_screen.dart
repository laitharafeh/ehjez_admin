import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TournamentRegistrantsScreen extends ConsumerWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentRegistrantsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final registrantsAsync =
        ref.watch(tournamentRegistrantsProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tournamentTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(s.registrants,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: registrantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (registrants) {
          if (registrants.isEmpty) {
            return Center(
              child: Text(
                s.noRegistrants,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  s.registrantCount(registrants.length),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: registrants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = registrants[index];
                    final name = r['name'] as String? ?? '—';
                    final phone = r['phone'] as String? ?? '—';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        phone,
                        style:
                            TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
