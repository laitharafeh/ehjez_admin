import 'package:flutter/material.dart';
import 'super_admin_scaffold.dart';

class SuperAdminAnalyticsScreen extends StatelessWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminScaffold(
      activePath: '/super-admin/analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminPageHeader(title: 'Analytics'),
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
