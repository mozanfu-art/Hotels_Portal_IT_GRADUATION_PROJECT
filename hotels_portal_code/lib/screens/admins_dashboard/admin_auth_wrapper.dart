import 'package:flutter/material.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart' as admin_welcome;
import 'hotel_admin/dashboard_screen.dart' as hotel_dashboard;
import 'ministry_admin/ministry_dashboard_screen.dart' as ministry_dashboard;

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoggedIn && authProvider.role == 'admin') {
      if (authProvider.isMinistryAdmin) {
        return ministry_dashboard.MinistryDashboardScreen();
      } else {
        return hotel_dashboard.HotelDashboardScreen();
      }
    } else {
      return admin_welcome.WelcomeScreen();
    }
  }
}
