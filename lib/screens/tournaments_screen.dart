import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/tournament_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TournamentsScreen extends ConsumerWidget {
  final String courtId;
  const TournamentsScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tournamentsAsync = ref.watch(tournamentsProvider(courtId));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tournaments),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ehjezGreen,
        foregroundColor: Colors.white,
        tooltip: s.createTournament,
        onPressed: () => _showCreateDialog(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return Center(
              child: Text(
                s.noTournaments,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final t = tournaments[index];
              final registrationList =
                  t['tournament_registrations'] as List? ?? [];
              final count = registrationList.isNotEmpty
                  ? (registrationList[0]['count'] as num?)?.toInt() ?? 0
                  : 0;
              final isActive = t['is_active'] as bool? ?? false;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        isActive ? ehjezGreen : Colors.grey.shade300,
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(
                    t['title'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    s.tournamentSubtitle(
                      t['date'] as String? ?? '',
                      t['time'] as String? ?? '',
                      count,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/tournaments/$courtId/${t['id'] as String}',
                    extra: t['title'] as String? ?? '',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref, S s) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '16');
    final feeCtrl = TextEditingController(text: '0');
    final prizeCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    bool isActive = true;
    bool isLoading = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.createTournament),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: s.tournamentTitle),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration:
                      InputDecoration(labelText: s.tournamentDescription),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(selectedDate == null
                            ? s.selectDate
                            : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(selectedTime == null
                            ? s.selectTime
                            : selectedTime!.format(ctx)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: s.maxParticipants),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: feeCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: s.entryFee),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: prizeCtrl,
                  decoration: InputDecoration(labelText: s.prize),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(s.active),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: ehjezGreen,
                      onChanged: (v) => setState(() => isActive = v),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ehjezGreen),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        setState(() => error = s.titleRequired);
                        return;
                      }
                      if (selectedDate == null || selectedTime == null) {
                        setState(
                            () => error = '${s.selectDate} / ${s.selectTime}');
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        error = null;
                      });
                      try {
                        final dateStr =
                            '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                        final timeStr =
                            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                        await TournamentService.createTournament(
                          courtId: courtId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          date: dateStr,
                          time: timeStr,
                          maxParticipants:
                              int.tryParse(maxCtrl.text.trim()) ?? 16,
                          entryFee:
                              int.tryParse(feeCtrl.text.trim()) ?? 0,
                          prize: prizeCtrl.text.trim(),
                          isActive: isActive,
                        );
                        ref.invalidate(tournamentsProvider(courtId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.tournamentCreated),
                              backgroundColor: ehjezGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          error = e.toString();
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
