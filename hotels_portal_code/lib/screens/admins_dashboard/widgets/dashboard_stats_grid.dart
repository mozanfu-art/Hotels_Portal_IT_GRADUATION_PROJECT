import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_booking_app/providers/analytics_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        // Define the grid delegate here to be used for both loading and data states
        const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350, // Max width for each item
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8, // Width-to-height ratio
        );

        // Display placeholders while loading
        if (analyticsProvider.isLoading) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: gridDelegate,
            itemCount: 6, // Display 6 placeholder cards
            itemBuilder: (context, index) {
              return const _StatCardPlaceholder();
            },
          );
        }

        if (analyticsProvider.error != null) {
          return Center(child: Text('Error: ${analyticsProvider.error}'));
        }

        final statsData = analyticsProvider.dashboardStats ?? {};

        final numberFormatter = NumberFormat.compact(locale: 'en_US');
        final currencyFormatter = NumberFormat.compactCurrency(
          symbol: '\$',
          locale: 'en_US',
        );

        final List<Map<String, dynamic>> stats = [
          {
            'number': numberFormatter.format(statsData['totalHotels'] ?? 0),
            'label': 'Registered Hotels',
            'icon': 'icons/hotel.png',
            'isClickable': true,
            'route': '/hotel-registry',
          },
          {
            'number': numberFormatter.format(statsData['approvedHotels'] ?? 0),
            'label': 'Active Licenses',
            'icon': Icons.description,
          },
          {
            'number': numberFormatter.format(statsData['totalGuests'] ?? 0),
            'label': 'Total Guests',
            'icon': Icons.group,
          },
          {
            'number': currencyFormatter.format(statsData['totalRevenue'] ?? 0),
            'label': 'Tourism Revenue',
            'icon': Icons.attach_money,
          },
          {
            'number': numberFormatter.format(
              statsData['pendingInspections'] ?? 0,
            ),
            'label': 'Pending Inspections',
            'icon': Icons.search,
          },
          {
            'number': numberFormatter.format(
              statsData['complianceIssues'] ?? 0,
            ),
            'label': 'Compliance Issues',
            'icon': Icons.warning,
          },
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _StatCard(
              number: stat['number'],
              label: stat['label'],
              icon: stat['icon'],
              isClickable: stat['isClickable'] ?? false,
              route: stat['route'],
            );
          },
        );
      },
    );
  }
}

class _StatCardPlaceholder extends StatefulWidget {
  const _StatCardPlaceholder();

  @override
  State<_StatCardPlaceholder> createState() => _StatCardPlaceholderState();
}

class _StatCardPlaceholderState extends State<_StatCardPlaceholder>
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Placeholder color
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
              const Spacer(),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String number;
  final String label;
  final dynamic icon;
  final bool isClickable;
  final String? route;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
    this.isClickable = false,
    this.route,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCardTap() {
    if (widget.isClickable && widget.route != null) {
      Navigator.pushNamed(context, widget.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF004C4C),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: widget.icon is String
                      ? Image.asset(
                          widget.icon,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.apartment,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : Icon(widget.icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            const Spacer(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.number,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (widget.isClickable) {
      return InkWell(
        onTap: _onCardTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
