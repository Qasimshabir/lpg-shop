import 'package:flutter/material.dart';
import '../lpg/lpg_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, redirect to LPG Dashboard
    // You can expand this to show different dashboards based on user type
    return const LPGDashboardScreen();
  }
}
