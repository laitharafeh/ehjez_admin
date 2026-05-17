import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kSideNavWidth = 220.0;
const _kBrandGreen = Color(0xFF068631);

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.label, this.path);
}

const _navItems = [
  _NavItem(Icons.groups_outlined, 'Members', '/super-admin'),
  _NavItem(Icons.calendar_today_outlined, 'Reservations', '/super-admin/reservations'),
  _NavItem(Icons.bar_chart_outlined, 'Analytics', '/super-admin/analytics'),
  _NavItem(Icons.settings_outlined, 'Settings', '/super-admin/settings'),
];

/// Wraps every super-admin screen with the persistent left side-nav.
///
/// [activePath] should match one of the [_navItems] paths so the correct
/// item is highlighted. For nested routes (e.g. /super-admin/courts/:id)
/// pass the parent path ('/super-admin') to keep "Members" active.
class SuperAdminScaffold extends StatelessWidget {
  final Widget child;
  final String activePath;

  const SuperAdminScaffold({
    super.key,
    required this.child,
    required this.activePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          _SideNav(activePath: activePath),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EBE8)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final String activePath;
  const _SideNav({required this.activePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSideNavWidth,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand header
          Container(
            height: 64,
            color: _kBrandGreen,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              'ehjez',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Nav items
          ...(_navItems.map((item) => _NavTile(
                item: item,
                isActive: activePath == item.path,
              ))),
          const Spacer(),
          // Logout
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EBE8)),
          ListTile(
            leading: const Icon(Icons.logout, size: 20, color: Colors.grey),
            title: const Text(
              'Sign out',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTile({required this.item, required this.isActive});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hovered = _hovered && !active;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () => context.go(widget.item.path),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? _kBrandGreen.withValues(alpha: 0.08)
                : hovered
                    ? Colors.grey.withValues(alpha: 0.06)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: active ? _kBrandGreen : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: active ? _kBrandGreen : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? _kBrandGreen : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
