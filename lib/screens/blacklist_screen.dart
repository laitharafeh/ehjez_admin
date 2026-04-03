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
      appBar: AppBar(title: const Text('Blacklisted Numbers')),
      body: blacklistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                  SizedBox(height: 12),
                  Text('No blacklisted numbers.'),
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
                  label: const Text('Unban'),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Unban number?'),
        content: Text('Remove $phone from the blacklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Unban'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(blacklistProvider.notifier).unblacklist(phone);
    }
  }
}
