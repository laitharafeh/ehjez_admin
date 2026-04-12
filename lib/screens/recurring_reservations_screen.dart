import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:ehjez_admin/services/recurring_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringReservationsScreen extends ConsumerWidget {
  final String courtId;
  const RecurringReservationsScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final recurringAsync = ref.watch(recurringReservationsProvider(courtId));

    return Scaffold(
      appBar: AppBar(title: Text(s.recurringReservations)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ehjezGreen,
        foregroundColor: Colors.white,
        tooltip: s.createRecurring,
        onPressed: () => _showCreateDialog(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.noRecurring,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _RecurringCard(item: items[i], courtId: courtId, ref: ref),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref, S s) async {
    List<String> sizes = [];
    int maxFields = 1;
    try {
      final rows = await CourtService.getCourtSizes(courtId);
      sizes = rows.map((r) => r['size'] as String).toList();
      if (sizes.isNotEmpty) {
        maxFields =
            (rows.first['number_of_fields'] as num?)?.toInt() ?? 1;
      }
    } catch (_) {}

    if (!context.mounted) return;
    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sizes found for this court.')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final fieldCtrl = TextEditingController(text: '1');
    String selectedSize = sizes.first;
    int selectedDay = 1; // Monday
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
    int selectedDuration = 1;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.createRecurring),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: s.nameField),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration:
                      InputDecoration(labelText: s.phoneNumberField),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration:
                      InputDecoration(labelText: s.sizesLabel),
                  items: sizes
                      .map((sz) =>
                          DropdownMenuItem(value: sz, child: Text(sz)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSize = v ?? selectedSize;
                      final row = []; // could refetch but keep simple
                      maxFields = 1;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fieldCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: s.fieldNumber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                            labelText: '${s.priceOneHour}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Day of week
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration:
                      InputDecoration(labelText: s.dayOfWeek),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                        value: i, child: Text(s.weekdayShort[i])),
                  ),
                  onChanged: (v) =>
                      setState(() => selectedDay = v ?? selectedDay),
                ),
                const SizedBox(height: 8),
                // Time
                OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(selectedTime.format(ctx)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Duration
                DropdownButtonFormField<int>(
                  value: selectedDuration,
                  decoration:
                      InputDecoration(labelText: s.selectDuration),
                  items: [
                    DropdownMenuItem(value: 1, child: Text(s.oneHour)),
                    DropdownMenuItem(
                        value: 2, child: Text(s.twoHours)),
                  ],
                  onChanged: (v) => setState(
                      () => selectedDuration = v ?? selectedDuration),
                ),
                const SizedBox(height: 8),
                // Start date
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${s.startDate}: ${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 4),
                // End date (optional)
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_busy_outlined, size: 16),
                  label: Text(endDate == null
                      ? s.endDate
                      : '${s.endDate.split('(')[0].trim()}: ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate
                          .add(const Duration(days: 30)),
                      firstDate: startDate,
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
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
              style:
                  FilledButton.styleFrom(backgroundColor: ehjezGreen),
              onPressed: loading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          phoneCtrl.text.trim().isEmpty) {
                        setState(() =>
                            error = '${s.nameField} / ${s.phoneNumberField}');
                        return;
                      }
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        final timeStr =
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                        final startStr =
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
                        final endStr = endDate == null
                            ? null
                            : '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';

                        final count =
                            await RecurringService.createRecurring(
                          courtId: courtId,
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          size: selectedSize,
                          fieldNumber:
                              int.tryParse(fieldCtrl.text.trim()) ?? 1,
                          startTime: timeStr,
                          duration: selectedDuration,
                          dayOfWeek: selectedDay,
                          price: double.tryParse(
                                  priceCtrl.text.trim()) ??
                              0,
                          startDate: startStr,
                          endDate: endStr,
                        );
                        ref.invalidate(
                            recurringReservationsProvider(courtId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${s.recurringCreated} ${s.recurringScheduled(count)}'),
                              backgroundColor: ehjezGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          loading = false;
                          error = e.toString();
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(s.confirm),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recurring card ─────────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String courtId;
  final WidgetRef ref;
  const _RecurringCard(
      {required this.item, required this.courtId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = item['name'] as String? ?? '—';
    final phone = item['phone'] as String? ?? '';
    final size = item['size'] as String? ?? '';
    final dayOfWeek = (item['day_of_week'] as num?)?.toInt() ?? 0;
    final startTime = (item['start_time'] as String? ?? '').substring(0, 5);
    final duration = (item['duration'] as num?)?.toInt() ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final endDate = item['end_date'] as String?;

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: ehjezGreen.withOpacity(0.12),
          child:
              Icon(Icons.repeat_outlined, color: ehjezGreen, size: 20),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.recurringSubtitle(
                  s.weekdayShort[dayOfWeek], startTime, size, phone),
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '${s.durationHours(duration)} · ${s.totalSpendAmount(price)}'
              '${endDate != null ? ' · until $endDate' : ''}',
              style: TextStyle(
                  color: ehjezGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: s.recurringDeleted,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.recurringReservations),
                content: Text(s.recurringDeleted),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.remove,
                        style:
                            const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await RecurringService.deleteRecurring(
                  item['id'] as int);
              ref.invalidate(recurringReservationsProvider(courtId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.recurringDeleted)),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
