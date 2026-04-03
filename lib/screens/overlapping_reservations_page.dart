import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverlappingReservationsPage extends ConsumerWidget {
  final String courtId;
  final String size;
  final DateTime date;
  final DateTime slotStart;
  final DateTime slotEnd;

  const OverlappingReservationsPage({
    required this.courtId,
    required this.size,
    required this.date,
    required this.slotStart,
    required this.slotEnd,
    super.key,
  });

  String _formatTime(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    OverlapEntry entry,
    OverlapArgs args,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text(
          'Are you sure you want to delete this reservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(overlappingReservationsProvider(args).notifier)
          .deleteReservation(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (
      courtId: courtId,
      size: size,
      date: date.toIso8601String().split('T')[0],
      slotStart: slotStart,
      slotEnd: slotEnd,
    );

    final overlapsAsync = ref.watch(overlappingReservationsProvider(args));

    return Scaffold(
      appBar: AppBar(title: const Text('Overlapping Reservations')),
      body: overlapsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (overlaps) {
          if (overlaps.isEmpty) {
            return const Center(child: Text('No overlapping reservations.'));
          }
          return ListView.separated(
            itemCount: overlaps.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final entry = overlaps[i];
              return ListTile(
                title: Text('Name: ${entry.name}'),
                subtitle: Text(
                  '${_formatTime(entry.start)} – ${_formatTime(entry.end)} '
                  '(${entry.duration}h)\n'
                  'Phone: ${entry.phone}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref, entry, args),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
