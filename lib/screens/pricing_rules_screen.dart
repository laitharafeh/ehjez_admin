import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:ehjez_admin/services/pricing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PricingRulesScreen extends ConsumerWidget {
  final String courtId;
  const PricingRulesScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final rulesAsync = ref.watch(pricingRulesProvider(courtId));

    return Scaffold(
      appBar: AppBar(title: Text(s.pricingRules)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ehjezGreen,
        foregroundColor: Colors.white,
        tooltip: s.createPricingRule,
        onPressed: () => _showCreateDialog(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.noPricingRules,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _RuleCard(rule: rules[i], courtId: courtId, ref: ref),
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref, S s) async {
    // Fetch court sizes
    List<String> sizes = [];
    try {
      final rows = await CourtService.getCourtSizes(courtId);
      sizes = rows.map((r) => r['size'] as String).toList();
    } catch (_) {}

    if (!context.mounted) return;
    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sizes found for this court.')),
      );
      return;
    }

    final labelCtrl = TextEditingController();
    final p1Ctrl = TextEditingController();
    final p2Ctrl = TextEditingController();
    String selectedSize = sizes.first;
    bool isOneOff = false;
    Set<int> selectedDays = {};
    DateTime? specificDate;
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.createPricingRule),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rule name
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    labelText: s.ruleLabel,
                    hintText: s.ruleLabelHint,
                  ),
                ),
                const SizedBox(height: 12),
                // Size selector
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  decoration:
                      InputDecoration(labelText: s.sizesLabel),
                  items: sizes
                      .map((sz) =>
                          DropdownMenuItem(value: sz, child: Text(sz)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedSize = v ?? selectedSize),
                ),
                const SizedBox(height: 12),
                // Rule type toggle
                Row(
                  children: [
                    Expanded(
                      child: _TypeBtn(
                        label: s.recurringDays,
                        selected: !isOneOff,
                        onTap: () => setState(() => isOneOff = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeBtn(
                        label: s.oneOffDate,
                        selected: isOneOff,
                        onTap: () => setState(() => isOneOff = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Day selector or date picker
                if (!isOneOff) ...[
                  Text(s.selectDays,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final selected = selectedDays.contains(i);
                      return FilterChip(
                        label: Text(s.weekdayShort[i]),
                        selected: selected,
                        selectedColor: ehjezGreen.withOpacity(0.2),
                        checkmarkColor: ehjezGreen,
                        onSelected: (_) => setState(() {
                          if (selected) {
                            selectedDays.remove(i);
                          } else {
                            selectedDays.add(i);
                          }
                        }),
                      );
                    }),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(specificDate == null
                        ? s.selectDate
                        : '${specificDate!.year}-${specificDate!.month.toString().padLeft(2, '0')}-${specificDate!.day.toString().padLeft(2, '0')}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 30)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => specificDate = picked);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                // Prices
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: p1Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            InputDecoration(labelText: s.priceOneHour),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: p2Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            InputDecoration(labelText: s.priceTwoHours),
                      ),
                    ),
                  ],
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
                      if (labelCtrl.text.trim().isEmpty) {
                        setState(() => error = s.titleRequired);
                        return;
                      }
                      if (!isOneOff && selectedDays.isEmpty) {
                        setState(() => error = s.selectDays);
                        return;
                      }
                      if (isOneOff && specificDate == null) {
                        setState(() => error = s.selectDate);
                        return;
                      }
                      final p1 =
                          double.tryParse(p1Ctrl.text.trim()) ?? 0;
                      final p2 =
                          double.tryParse(p2Ctrl.text.trim()) ?? 0;
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await PricingService.createRule(
                          courtId: courtId,
                          size: selectedSize,
                          label: labelCtrl.text.trim(),
                          daysOfWeek:
                              isOneOff ? null : selectedDays.toList(),
                          specificDate: specificDate == null
                              ? null
                              : '${specificDate!.year}-${specificDate!.month.toString().padLeft(2, '0')}-${specificDate!.day.toString().padLeft(2, '0')}',
                          price1: p1,
                          price2: p2,
                        );
                        ref.invalidate(pricingRulesProvider(courtId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.ruleCreated),
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

// ── Rule card ──────────────────────────────────────────────────────────────────

class _RuleCard extends StatelessWidget {
  final Map<String, dynamic> rule;
  final String courtId;
  final WidgetRef ref;
  const _RuleCard(
      {required this.rule, required this.courtId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = rule['label'] as String? ?? '';
    final size = rule['size'] as String? ?? '';
    final p1 = (rule['price1'] as num?)?.toDouble() ?? 0;
    final p2 = (rule['price2'] as num?)?.toDouble() ?? 0;
    final specificDate = rule['specific_date'] as String?;
    final daysOfWeek =
        (rule['days_of_week'] as List?)?.cast<int>() ?? [];

    String appliesDesc;
    if (specificDate != null) {
      appliesDesc = specificDate;
    } else {
      appliesDesc = daysOfWeek.map((d) => s.weekdayShort[d]).join(', ');
    }

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: ehjezGreen.withOpacity(0.12),
          child: Icon(
            specificDate != null
                ? Icons.event_outlined
                : Icons.repeat_outlined,
            color: ehjezGreen,
            size: 20,
          ),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$size · ${s.appliesOn}: $appliesDesc',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              '1h: ${p1.toStringAsFixed(0)} JOD  ·  2h: ${p2.toStringAsFixed(0)} JOD',
              style: TextStyle(
                  color: ehjezGreen,
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: s.deleteRule,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.deleteRule),
                content: Text(s.confirmDeleteRule),
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
              await PricingService.deleteRule(rule['id'] as int);
              ref.invalidate(pricingRulesProvider(courtId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.ruleDeleted)),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? ehjezGreen : Colors.transparent,
          border: Border.all(
              color: selected ? ehjezGreen : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
