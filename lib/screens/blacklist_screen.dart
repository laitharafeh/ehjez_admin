import 'package:ehjez_admin/l10n/s.dart';
import 'package:ehjez_admin/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BlacklistScreen extends ConsumerWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blacklistAsync = ref.watch(blacklistProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).blacklistedNumbers)),
      body: blacklistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (entries) {
          final s = S.of(context);
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(s.noBlacklistedNumbers),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final dateStr = DateFormat('d MMM yyyy').format(entry.blacklistedAt.toLocal());
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.block, color: Colors.white, size: 20),
                ),
                title: Text(
                  entry.phone,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${entry.reason} · Blacklisted $dateStr'),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: Text(S.of(context).unban),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                  onPressed: () => _confirmUnban(context, ref, entry.phone),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmUnban(
    BuildContext context,
    WidgetRef ref,
    String phone,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
        return AlertDialog(
          title: Text(s.unbanNumber),
          content: Text(s.removeFromBlacklist(phone)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: Text(s.unban),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(blacklistProvider.notifier).unblacklist(phone);
    }
  }
}
