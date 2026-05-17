import 'package:flutter/material.dart';

import 'super_admin_scaffold.dart';

class SuperAdminCourtScreen extends StatelessWidget {
  final String courtId;
  const SuperAdminCourtScreen({super.key, required this.courtId});

  @override
  Widget build(BuildContext context) {
    return SuperAdminScaffold(
      activePath: '/super-admin', // keeps "Members" highlighted
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminPageHeader(title: 'Court Details', showBack: true),
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
