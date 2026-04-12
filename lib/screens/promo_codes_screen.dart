import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/promo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromoCodesScreen extends ConsumerWidget {
  final String courtId;
  const PromoCodesScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final codesAsync = ref.watch(promoCodesProvider(courtId));

    return Scaffold(
      appBar: AppBar(title: Text(s.promoCodes)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ehjezGreen,
        foregroundColor: Colors.white,
        tooltip: s.createPromoCode,
        onPressed: () => _showCreateDialog(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: codesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (codes) {
          // Summary bar
          final activeCodes = codes.where((c) => c['is_active'] == true).length;
          final totalUses = codes.fold<int>(
              0, (sum, c) => sum + ((c['uses_count'] as num?)?.toInt() ?? 0));

          return Column(
            children: [
              // Stats strip
              if (codes.isNotEmpty)
                Container(
                  color: ehjezGreen.withOpacity(0.07),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _Stat(
                          label: s.promoCodes,
                          value: '${codes.length}',
                          icon: Icons.discount_outlined),
                      const SizedBox(width: 16),
                      _Stat(
                          label: s.active,
                          value: '$activeCodes',
                          icon: Icons.check_circle_outline),
                      const SizedBox(width: 16),
                      _Stat(
                          label: s.usesLabel,
                          value: '$totalUses',
                          icon: Icons.people_outline),
                    ],
                  ),
                ),
              Expanded(
                child: codes.isEmpty
                    ? Center(
                        child: Text(
                          s.noPromoCodes,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: codes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _PromoCard(
                          code: codes[i],
                          courtId: courtId,
                          ref: ref,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, WidgetRef ref, S s) async {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    String type = 'percent';
    DateTime? validFrom;
    DateTime? validUntil;
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.createPromoCode),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code input
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: s.promoCode,
                    hintText: s.promoCodeHint,
                    suffixIcon: const Icon(Icons.discount_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Discount type toggle
                Text(s.discountType,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: _TypeBtn(
                      label: s.percentOff,
                      icon: Icons.percent,
                      selected: type == 'percent',
                      onTap: () => setState(() => type = 'percent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeBtn(
                      label: s.fixedAmount,
                      icon: Icons.attach_money,
                      selected: type == 'fixed',
                      onTap: () => setState(() => type = 'fixed'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Value
                TextField(
                  controller: valueCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: s.discountValue,
                    suffixText: type == 'percent' ? '%' : 'JOD',
                  ),
                ),
                const SizedBox(height: 12),

                // Max uses
                TextField(
                  controller: maxUsesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.maxUses,
                  ),
                ),
                const SizedBox(height: 12),

                // Date range
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.calendar_today, size: 14),
                      label: Text(
                        validFrom == null
                            ? s.validFrom
                            : '${validFrom!.day}/${validFrom!.month}/${validFrom!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 730)),
                        );
                        if (p != null) setState(() => validFrom = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.event_busy_outlined, size: 14),
                      label: Text(
                        validUntil == null
                            ? s.validUntil
                            : '${validUntil!.day}/${validUntil!.month}/${validUntil!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final p = await showDatePicker(
                          context: ctx,
                          initialDate: validFrom ??
                              DateTime.now()
                                  .add(const Duration(days: 30)),
                          firstDate: validFrom ?? DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 730)),
                        );
                        if (p != null) setState(() => validUntil = p);
                      },
                    ),
                  ),
                ]),

                if (error != null) ...[
                  const SizedBox(height: 10),
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
              style: FilledButton.styleFrom(backgroundColor: ehjezGreen),
              onPressed: loading
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      if (code.isEmpty) {
                        setState(
                            () => error = s.promoCode);
                        return;
                      }
                      final val =
                          double.tryParse(valueCtrl.text.trim());
                      if (val == null || val <= 0) {
                        setState(() => error = s.discountValue);
                        return;
                      }
                      if (type == 'percent' && val > 100) {
                        setState(() => error = 'Max 100%');
                        return;
                      }
                      setState(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        String _fmtDate(DateTime d) =>
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                        await PromoService.createCode(
                          courtId: courtId,
                          code: code,
                          type: type,
                          value: val,
                          maxUses: maxUsesCtrl.text.trim().isEmpty
                              ? null
                              : int.tryParse(maxUsesCtrl.text.trim()),
                          validFrom: validFrom == null
                              ? null
                              : _fmtDate(validFrom!),
                          validUntil: validUntil == null
                              ? null
                              : _fmtDate(validUntil!),
                        );
                        ref.invalidate(promoCodesProvider(courtId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.promoCreated),
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

// ── Promo card ─────────────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> code;
  final String courtId;
  final WidgetRef ref;
  const _PromoCard(
      {required this.code, required this.courtId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final codeStr = code['code'] as String? ?? '';
    final type = code['type'] as String? ?? 'percent';
    final value = (code['value'] as num?)?.toDouble() ?? 0;
    final isActive = code['is_active'] as bool? ?? false;
    final usesCount = (code['uses_count'] as num?)?.toInt() ?? 0;
    final maxUses = code['max_uses'] as int?;
    final validFrom = code['valid_from'] as String?;
    final validUntil = code['valid_until'] as String?;

    final isExpired = validUntil != null &&
        DateTime.tryParse(validUntil)?.isBefore(DateTime.now()) == true;
    final isExhausted = maxUses != null && usesCount >= maxUses;

    Color statusColor = ehjezGreen;
    String statusLabel = s.active;
    if (!isActive) {
      statusColor = Colors.grey;
      statusLabel = 'Inactive';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusLabel = 'Expired';
    } else if (isExhausted) {
      statusColor = Colors.orange;
      statusLabel = 'Exhausted';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: code chip + status badge + toggle + delete
            Row(
              children: [
                // Code chip
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: codeStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.codeCopied),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive && !isExpired && !isExhausted
                          ? ehjezGreen
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          codeStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy, color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    s.promoDiscount(type, value),
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                // Toggle
                Switch(
                  value: isActive,
                  activeColor: ehjezGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) async {
                    await PromoService.toggleActive(
                        code['id'] as int, val);
                    ref.invalidate(promoCodesProvider(courtId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              val ? s.promoActivated : s.promoDeactivated),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  tooltip: s.deletePromo,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(s.deletePromo),
                        content: Text(s.confirmDeletePromo),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(s.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(s.remove,
                                style: const TextStyle(
                                    color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await PromoService.deleteCode(code['id'] as int);
                      ref.invalidate(promoCodesProvider(courtId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.promoDeleted)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: usage + validity
            Row(
              children: [
                Icon(Icons.people_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  s.promoUsage(usesCount, maxUses),
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12),
                ),
                if (validFrom != null || validUntil != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _dateRange(validFrom, validUntil, s),
                    style: TextStyle(
                      color: isExpired
                          ? Colors.red.shade400
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateRange(String? from, String? until, S s) {
    if (from != null && until != null) return '$from → $until';
    if (from != null) return '${s.startsOn} $from';
    if (until != null) return '${s.expires} $until';
    return '';
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: ehjezGreen),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ]),
    ]);
  }
}

// ── Type button ────────────────────────────────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? ehjezGreen : Colors.transparent,
          border: Border.all(
              color: selected ? ehjezGreen : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
