import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/providers/analytics_provider.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_bookings_table.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/stats_card.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HotelDashboardScreen extends StatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  State<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends State<HotelDashboardScreen> {
  bool isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hotelId != null) {
        // Fetch both sets of stats
        Provider.of<AnalyticsProvider>(
          context,
          listen: false,
        ).fetchHotelDashboardStats(authProvider.hotelId!);
        Provider.of<AnalyticsProvider>(
          context,
          listen: false,
        ).fetchRoomStatusSummary(authProvider.hotelId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return Row(
            children: [
              HotelAdminSidebar(
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
                    if (!isMobile) Header(showBackButton: false),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Stats Grid
                            Consumer<AnalyticsProvider>(
                              builder: (context, analyticsProvider, child) {
                                if (analyticsProvider.isLoading &&
                                    analyticsProvider.hotelDashboardStats ==
                                        null) {
                                  return _buildStatsPlaceholder(isMobile);
                                }
                                if (analyticsProvider.error != null) {
                                  return Center(
                                    child: Text(
                                      'Error loading stats: ${analyticsProvider.error}',
                                    ),
                                  );
                                }

                                final stats =
                                    analyticsProvider.hotelDashboardStats ?? {};
                                final occupancyRate =
                                    stats['occupancyRate'] ?? 0.0;
                                final revenueToday =
                                    stats['revenueToday'] ?? 0.0;
                                final newBookings =
                                    stats['newBookingsThisWeek'] ?? 0;
                                final averageRating =
                                    stats['averageRating'] ?? 0.0;

                                return GridView.count(
                                  crossAxisCount: isMobile ? 1 : 4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    StatsCard(
                                      label: 'Occupancy Rate',
                                      value:
                                          '${occupancyRate.toStringAsFixed(1)}%',
                                      change: 'Live',
                                      icon: FontAwesomeIcons.hotel,
                                      iconColor: Colors.blue.shade600,
                                      iconBgColor: Colors.blue.shade100,
                                    ),
                                    StatsCard(
                                      label: 'Revenue Today',
                                      value: NumberFormat.compactCurrency(
                                        symbol: '\$',
                                      ).format(revenueToday),
                                      change: 'Completed Today',
                                      icon: FontAwesomeIcons.dollarSign,
                                      iconColor: Colors.green.shade600,
                                      iconBgColor: Colors.green.shade100,
                                    ),
                                    StatsCard(
                                      label: 'New Bookings',
                                      value: newBookings.toString(),
                                      change: 'This week',
                                      icon: FontAwesomeIcons.calendarCheck,
                                      iconColor: Colors.purple.shade600,
                                      iconBgColor: Colors.purple.shade100,
                                    ),
                                    StatsCard(
                                      label: 'Average Rating',
                                      value: averageRating.toStringAsFixed(1),
                                      change: 'Overall',
                                      icon: FontAwesomeIcons.star,
                                      iconColor: Colors.yellow.shade600,
                                      iconBgColor: Colors.yellow.shade100,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Bookings Table
                            const HotelBookingsTable(),
                            const SizedBox(height: 24),
                            // Room Status Summary
                            Text(
                              'Room Status Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Consumer<AnalyticsProvider>(
                              builder: (context, analyticsProvider, child) {
                                if (analyticsProvider.isLoading &&
                                    analyticsProvider.roomStatusSummary ==
                                        null) {
                                  return _buildRoomStatusPlaceholder(isMobile);
                                }
                                if (analyticsProvider.error != null) {
                                  return const Center(
                                    child: Text('Could not load room status.'),
                                  );
                                }
                                if (analyticsProvider.roomStatusSummary ==
                                        null ||
                                    analyticsProvider
                                        .roomStatusSummary!
                                        .isEmpty) {
                                  return const Center(
                                    child: Text('No rooms found.'),
                                  );
                                }

                                final summaryData =
                                    analyticsProvider.roomStatusSummary!;

                                return GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isMobile ? 2 : 4,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: summaryData.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final data = summaryData[index];
                                    final colors = [
                                      Colors.blue,
                                      Colors.green,
                                      Colors.purple,
                                      Colors.orange,
                                    ];
                                    return _RoomStatusCard(
                                      type: data['type'],
                                      occupied: data['occupied'],
                                      total: data['total'],
                                      color: colors[index % colors.length],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            const Footer(),
                          ],
                        ),
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

  Widget _buildStatsPlaceholder(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (index) => const _StatCardPlaceholder()),
    );
  }

  Widget _buildRoomStatusPlaceholder(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        4,
        (index) => const _StatCardPlaceholder(isRoomCard: true),
      ),
    );
  }
}

class _StatCardPlaceholder extends StatefulWidget {
  final bool isRoomCard;
  const _StatCardPlaceholder({this.isRoomCard = false});

  @override
  State<_StatCardPlaceholder> createState() => __StatCardPlaceholderState();
}

class __StatCardPlaceholderState extends State<_StatCardPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: widget.isRoomCard
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceholderBox(height: 14, width: 100),
                    const SizedBox(height: 12),
                    _buildPlaceholderBox(height: 24, width: 60),
                    const Spacer(),
                    _buildPlaceholderBox(height: 10, width: double.infinity),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPlaceholderBox(height: 14, width: 100),
                          const SizedBox(height: 12),
                          _buildPlaceholderBox(height: 24, width: 60),
                          const SizedBox(height: 8),
                          _buildPlaceholderBox(height: 12, width: 120),
                        ],
                      ),
                    ),
                    _buildPlaceholderBox(height: 50, width: 50),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _RoomStatusCard extends StatelessWidget {
  final String type;
  final int occupied;
  final int total;
  final Color color;

  const _RoomStatusCard({
    required this.type,
    required this.occupied,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = total > 0 ? occupied / total : 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$occupied / $total',
              style: TextStyle(
                color: const Color(0xFF004d40),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}
