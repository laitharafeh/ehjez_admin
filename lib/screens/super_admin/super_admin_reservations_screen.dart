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
              'Reservations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
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
