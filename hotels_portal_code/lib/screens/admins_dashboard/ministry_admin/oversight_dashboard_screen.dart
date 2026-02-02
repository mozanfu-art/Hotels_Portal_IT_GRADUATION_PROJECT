import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/bookings_table.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/stats_card.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class OversightDashboardScreen extends StatefulWidget {
  const OversightDashboardScreen({super.key});

  @override
  State<OversightDashboardScreen> createState() =>
      _OversightDashboardScreenState();
}

class _OversightDashboardScreenState extends State<OversightDashboardScreen> {
  bool isSidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return Row(
            children: [
              // Sidebar
              if (!isMobile || isSidebarOpen)
                MinistryAdminSidebar(
                  isMobile: isMobile,
                  isOpen: isSidebarOpen,
                  onToggle: () {
                    setState(() {
                      isSidebarOpen = !isSidebarOpen;
                    });
                  },
                ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Mobile menu button
                    if (isMobile)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isSidebarOpen = !isSidebarOpen;
                                });
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.bars,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Header
                    if (!isMobile) const MinistryAdminHeader(),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Stats Grid
                            GridView.count(
                              crossAxisCount: isMobile ? 1 : 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                StatsCard(
                                  label: 'Hotels',
                                  value: '150',
                                  change: '+5 from last month',
                                  icon: FontAwesomeIcons.hotel,
                                  iconColor: Colors.blue.shade600,
                                  iconBgColor: Colors.blue.shade100,
                                ),
                                StatsCard(
                                  label: 'Licenses',
                                  value: '120',
                                  change: '+10 issued',
                                  icon: FontAwesomeIcons.certificate,
                                  iconColor: Colors.green.shade600,
                                  iconBgColor: Colors.green.shade100,
                                ),
                                StatsCard(
                                  label: 'Visitors',
                                  value: '50,000',
                                  change: '+15% from last year',
                                  icon: FontAwesomeIcons.users,
                                  iconColor: Colors.purple.shade600,
                                  iconBgColor: Colors.purple.shade100,
                                ),
                                StatsCard(
                                  label: 'Revenue',
                                  value: '\$1,200,000',
                                  change: '+20% from last quarter',
                                  icon: FontAwesomeIcons.dollarSign,
                                  iconColor: Colors.yellow.shade600,
                                  iconBgColor: Colors.yellow.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.add),
                                  label: Text('New License'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004d40),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.schedule),
                                  label: Text('Schedule Inspection'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF004d40),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Recent Activities or something
                            const BookingsTable(), // or a different table
                          ],
                        ),
                      ),
                    ),
                    const Footer(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
