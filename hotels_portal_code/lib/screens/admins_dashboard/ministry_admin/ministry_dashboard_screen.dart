import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/providers/analytics_provider.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/bookings_table.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/dashboard_stats_grid.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MinistryDashboardScreen extends StatefulWidget {
  const MinistryDashboardScreen({super.key});

  @override
  State<MinistryDashboardScreen> createState() =>
      _MinistryDashboardScreenState();
}

class _MinistryDashboardScreenState extends State<MinistryDashboardScreen> {
  bool isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    // Fetch stats when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      ).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminName = authProvider.currentAdmin?.fName ?? 'Admin';
    final welcomeMessage = 'Welcome back, $adminName';

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

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Mobile Menu
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
                              icon: const FaIcon(
                                FontAwesomeIcons.bars,
                                color: Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header
                    if (!isMobile)
                      MinistryAdminHeader(
                        title: welcomeMessage,
                        showBackButton: false,
                      ),

                    // Content
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Stats Grid
                                  const DashboardStatsGrid(),

                                  const SizedBox(height: 24),

                                  _buildRecentActivities(),
                                  const SizedBox(height: 24),

                                  // Recent Activities
                                  const BookingsTable(),
                                ],
                              ),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                  ),
                                  child: const Footer(),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

Widget _buildRecentActivities() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF004d40),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Activity>>(
            stream: ActivityService().getRecentActivitiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No recent activities.");
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final activity = snapshot.data![index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(activity.type),
                    subtitle: Text(activity.description),
                    trailing: Text(
                      DateFormat(
                        'yyyy-MM-dd – kk:mm',
                      ).format(activity.timestamp.toDate()),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}
