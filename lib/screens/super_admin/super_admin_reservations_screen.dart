import 'package:flutter/material.dart';
import 'super_admin_scaffold.dart';

class SuperAdminReservationsScreen extends StatelessWidget {
  const SuperAdminReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminScaffold(
      activePath: '/super-admin/reservations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SuperAdminPageHeader(title: 'Reservations'),
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
