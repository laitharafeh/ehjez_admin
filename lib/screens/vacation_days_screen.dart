import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class VacationDaysScreen extends ConsumerStatefulWidget {
  final String courtId;
  const VacationDaysScreen({super.key, required this.courtId});

  @override
  ConsumerState<VacationDaysScreen> createState() => _VacationDaysScreenState();
}

class _VacationDaysScreenState extends ConsumerState<VacationDaysScreen> {
  // Pure UI state — calendar focus has nothing to do with server data.
  DateTime _focusedDay = DateTime.now();
  // Tracks in-flight mutations so the UI can disable interactions.
  bool _isSaving = false;

  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _toggleDay(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_normalise(day));
    setState(() => _isSaving = true);
    try {
      await ref
          .read(vacationDaysProvider(widget.courtId).notifier)
          .toggleDay(day, dateStr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorUpdatingVacation('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearAll(Set<DateTime> current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.clearAllTitle),
          content: Text(s.clearAllBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.clearAll),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(vacationDaysProvider(widget.courtId).notifier)
          .clearAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorClearingVacation('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vacationAsync = ref.watch(vacationDaysProvider(widget.courtId));

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).vacationDays),
        actions: [
          vacationAsync.whenData((days) => days).valueOrNull?.isNotEmpty == true
              ? TextButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _clearAll(vacationAsync.valueOrNull ?? {}),
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                  label: Text(
                    S.of(context).clearAll,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: vacationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading vacation days: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (vacationDays) => Column(
          children: [
            // Info banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      S.of(context).tapDateToMarkVacation,
                      style:
                          TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _legendDot(Colors.red.shade300),
                  const SizedBox(width: 6),
                  Text(S.of(context).vacationClosed,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  _legendDot(ehjezGreen),
                  const SizedBox(width: 6),
                  Text(S.of(context).today, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Calendar
            TableCalendar(
              availableGestures: AvailableGestures.horizontalSwipe,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  vacationDays.contains(_normalise(day)),
              onDaySelected: (selectedDay, focusedDay) {
                if (_isSaving) return;
                setState(() => _focusedDay = focusedDay);
                _toggleDay(selectedDay);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.red.shade300,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: ehjezGreen,
                  shape: BoxShape.circle,
                ),
              ),
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              calendarFormat: CalendarFormat.month,
              onFormatChanged: null,
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),

            const Divider(),

            // List of selected vacation days
            Expanded(
              child: vacationDays.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.beach_access_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            S.of(context).noVacationDays,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 15),
                          ),
                          Text(
                            S.of(context).tapDateToClose,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        Text(
                          S.of(context).vacationDaysCount(vacationDays.length),
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ...(vacationDays.toList()..sort()).map((day) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.beach_access,
                                  color: Colors.red.shade400, size: 18),
                            ),
                            title: Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(day),
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.grey.shade400, size: 18),
                              onPressed:
                                  _isSaving ? null : () => _toggleDay(day),
                              tooltip: S.of(context).remove,
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isSaving
          ? LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              color: ehjezGreen,
              minHeight: 3,
            )
          : null,
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
