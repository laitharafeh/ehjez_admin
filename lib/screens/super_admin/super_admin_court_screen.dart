import 'package:ehjez_admin/constants.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:ehjez_admin/services/court_service.dart';
import 'package:ehjez_admin/widgets/shimmer_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'super_admin_scaffold.dart';

class SuperAdminCourtScreen extends ConsumerStatefulWidget {
  final String courtId;
  const SuperAdminCourtScreen({super.key, required this.courtId});

  @override
  ConsumerState<SuperAdminCourtScreen> createState() =>
      _SuperAdminCourtScreenState();
}

class _SuperAdminCourtScreenState extends ConsumerState<SuperAdminCourtScreen> {
  bool _toggling = false;

  Future<void> _toggle(bool newValue) async {
    setState(() => _toggling = true);
    try {
      await CourtService.setCourtActive(widget.courtId, active: newValue);
      ref.invalidate(courtDetailProvider(widget.courtId));
      ref.invalidate(allCourtsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courtAsync = ref.watch(courtDetailProvider(widget.courtId));

    return SuperAdminScaffold(
      activePath: '/super-admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          courtAsync.when(
            loading: () => const SuperAdminPageHeader(
                title: 'Court Details', showBack: true),
            error: (_, __) => const SuperAdminPageHeader(
                title: 'Court Details', showBack: true),
            data: (court) => SuperAdminPageHeader(
              title: court['name'] as String? ?? 'Court Details',
              showBack: true,
            ),
          ),
          Expanded(
            child: courtAsync.when(
              loading: () => const _CourtDetailSkeleton(),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (court) => _CourtDetailBody(
                court: court,
                toggling: _toggling,
                onToggle: _toggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _CourtDetailBody extends StatelessWidget {
  final Map<String, dynamic> court;
  final bool toggling;
  final ValueChanged<bool> onToggle;

  const _CourtDetailBody({
    required this.court,
    required this.toggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = court['name'] as String? ?? '—';
    final imageUrl = court['image_url'] as String?;
    final isActive = court['is_active'] as bool? ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Court card ──────────────────────────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image
                    SizedBox(
                      height: 180,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _ImagePlaceholder())
                          : const _ImagePlaceholder(),
                    ),
                    // Name + status badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatusBadge(isActive: isActive),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Visibility toggle ───────────────────────────────────────
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? ehjezGreen.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isActive
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: isActive ? ehjezGreen : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Visible on app',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isActive
                                  ? 'Customers can discover and book this court'
                                  : 'Hidden — customers cannot see or book this court',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? ehjezGreen
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      toggling
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: ehjezGreen,
                              ),
                            )
                          : Switch(
                              value: isActive,
                              activeThumbColor: ehjezGreen,
                              activeTrackColor: ehjezGreen.withValues(alpha: 0.4),
                              onChanged: onToggle,
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? ehjezGreen.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? ehjezGreen.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? ehjezGreen : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? ehjezGreen : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image placeholder ─────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Icon(Icons.sports_tennis, size: 48, color: Colors.white54),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _CourtDetailSkeleton extends StatelessWidget {
  const _CourtDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShimmerBox(height: 180, borderRadius: 0),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                              child: ShimmerBox(height: 20, borderRadius: 4)),
                          const SizedBox(width: 12),
                          ShimmerBox(width: 70, height: 24, borderRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      ShimmerBox(width: 40, height: 40, borderRadius: 10),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(height: 14, width: 120, borderRadius: 4),
                            const SizedBox(height: 6),
                            ShimmerBox(height: 11, borderRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShimmerBox(width: 48, height: 28, borderRadius: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
