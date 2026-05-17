import 'package:flutter/material.dart';
import 'super_admin_scaffold.dart';

class SuperAdminSettingsScreen extends StatelessWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminScaffold(
      activePath: '/super-admin/settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminPageHeader(title: 'Settings'),
          const Expanded(
            child: Center(
              child: Text(
                'Coming soon.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
