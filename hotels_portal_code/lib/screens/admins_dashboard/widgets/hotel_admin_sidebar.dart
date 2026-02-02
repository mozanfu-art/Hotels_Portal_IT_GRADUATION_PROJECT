import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:provider/provider.dart';

class HotelAdminSidebar extends StatefulWidget {
  final bool isMobile;
  final bool isOpen;
  final VoidCallback onToggle;

  const HotelAdminSidebar({
    super.key,
    required this.isMobile,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<HotelAdminSidebar> createState() => _HotelAdminSidebarState();
}

class _HotelAdminSidebarState extends State<HotelAdminSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final authProvider = Provider.of<AuthProvider>(context);
      if (authProvider.hotelId != null) {
        Provider.of<HotelProvider>(
          context,
          listen: false,
        ).getHotel(authProvider.hotelId!);
        _isDataLoaded = true;
      }
    }
  }

  @override
  void didUpdateWidget(covariant HotelAdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hotelProvider = Provider.of<HotelProvider>(context);
    final hotel = hotelProvider.hotel;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.isMobile
              ? MediaQuery.of(context).size.width * 0.8
              : 280,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: const Color(0xFF004d40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          transform: Matrix4.translationValues(
            widget.isMobile
                ? (widget.isOpen ? 0 : -MediaQuery.of(context).size.width * 0.8)
                : 0,
            0,
            0,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF004d40),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Hotel Icon
                    Image.asset(
                      'assets/images/hotelicon.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 10),
                    // Hotel Name
                    Text(
                      hotel?.hotelName ?? 'Hotel Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    // Admin Dashboard
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildMenuItem(
                      FontAwesomeIcons.tachometerAlt,
                      'Dashboard',
                      Colors.blue,
                      '/hotel-dashboard',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.calendarCheck,
                      'Bookings',
                      Colors.red,
                      '/hotel-bookings-management',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.bed,
                      'Rooms',
                      Colors.orange,
                      '/hotel-room-management',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.users,
                      'Guests',
                      Colors.purple,
                      '/hotel-guest-management',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.star,
                      'Reviews',
                      Colors.amber,
                      '/hotel-reviews',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.fileAlt,
                      'Reports',
                      Colors.teal,
                      '/hotel-reports-analytics',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.bell,
                      'Notifications',
                      Colors.yellow,
                      '/hotel-notifications',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.cog,
                      'Settings',
                      Colors.grey,
                      '/hotel-admin-settings',
                    ),
                  ],
                ),
              ),
              // Logout
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    authProvider.signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color iconColor,
    String? route,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF004d40).withOpacity(0.1),
      ),
      child: ListTile(
        leading: FaIcon(icon, color: iconColor, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          if (route != null) {
            final currentRoute = ModalRoute.of(context)?.settings.name;
            if (currentRoute != route) {
              if (route == '/hotel-dashboard') {
                Navigator.of(context).pushReplacementNamed(route);
              } else {
                Navigator.of(context).pushNamed(route);
              }
            }
          }
          if (widget.isMobile) {
            widget.onToggle();
          }
        },
      ),
    );
  }
}
