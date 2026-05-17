import 'package:flutter/material.dart';
import 'super_admin_scaffold.dart';

class SuperAdminBillingScreen extends StatelessWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminScaffold(
      activePath: '/super-admin/billing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminPageHeader(title: 'Billing'),
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
