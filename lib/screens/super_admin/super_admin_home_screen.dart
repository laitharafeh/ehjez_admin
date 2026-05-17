import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import 'super_admin_scaffold.dart';

class SuperAdminHomeScreen extends ConsumerWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtsAsync = ref.watch(allCourtsProvider);

    return SuperAdminScaffold(
      activePath: '/super-admin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8EBE8), width: 1),
              ),
            ),
            child: const Text(
              'Members',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          // Content
          Expanded(
            child: courtsAsync.when(
              loading: () => const _SkeletonGrid(),
              error: (e, _) => Center(
                child: Text(
                  'Error loading courts: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (courts) => courts.isEmpty
                  ? const Center(child: Text('No courts found.'))
                  : _CourtsGrid(courts: courts),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> courts;
  const _CourtsGrid({required this.courts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 500
            ? 2
            : width < 800
                ? 3
                : width < 1200
                    ? 4
                    : 5;
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: courts.length,
          itemBuilder: (context, i) => _CourtCard(court: courts[i]),
        );
      },
    );
  }
}

class _CourtCard extends StatefulWidget {
  final Map<String, dynamic> court;
  const _CourtCard({required this.court});

  @override
  State<_CourtCard> createState() => _CourtCardState();
}

class _CourtCardState extends State<_CourtCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.court['image_url'] as String?;
    final name = widget.court['name'] as String? ?? 'Unnamed Court';
    final courtId = widget.court['id'] as String;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: _hovered ? 8 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go('/super-admin/courts/$courtId'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Court image
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : const _Placeholder(),
                        errorBuilder: (_, __, ___) => const _Placeholder(),
                      )
                    : const _Placeholder(),
                // Bottom gradient + name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC000000), Color(0x00000000)],
                        stops: [0.0, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Icon(Icons.sports_tennis, size: 48, color: Colors.white54),
    );
  }
}

// ─── Skeleton loading ──────────────────────────────────────────────────────────

/// Same responsive grid as _CourtsGrid, filled with skeleton cards.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 500
            ? 2
            : width < 800
                ? 3
                : width < 1200
                    ? 4
                    : 5;
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          // Show enough cards to fill ~2 rows
          itemCount: columns * 2,
          itemBuilder: (_, __) => const _SkeletonCard(),
        );
      },
    );
  }
}

/// Square card with a shimmer sweep + a darker bar at the bottom
/// that mirrors the name label area of the real card.
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({super.key});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base grey
              Container(color: const Color(0xFFE8E8E8)),
              // Shimmer sweep — light band travelling left → right
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.5 + _ctrl.value * 3, 0),
                      end: Alignment(-0.8 + _ctrl.value * 3, 0),
                      colors: const [
                        Colors.transparent,
                        Color(0x66FFFFFF),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Darker bar mimicking the name label gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 52,
                  color: const Color(0xFFD0D0D0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
