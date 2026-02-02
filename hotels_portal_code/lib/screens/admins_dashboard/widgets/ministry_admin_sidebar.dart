import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MinistryAdminSidebar extends StatefulWidget {
  final bool isMobile;
  final bool isOpen;
  final VoidCallback onToggle;

  const MinistryAdminSidebar({
    super.key,
    required this.isMobile,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<MinistryAdminSidebar> createState() => _MinistryAdminSidebarState();
}

class _MinistryAdminSidebarState extends State<MinistryAdminSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  void didUpdateWidget(covariant MinistryAdminSidebar oldWidget) {
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

  // 🔹 Settings dialog popup
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text(
          'This is a placeholder for the Platform Settings content. In the future, load from Navigating screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 🔹 Revenue & Taxes dialog popup
  void _showRevenueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revenue & Taxes'),
        content: const Text(
          'This is a placeholder for the Platform Revenue & Taxes content. In the future, load from Navigating screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

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
                    Image.asset(
                      'assets/images/hotelicon.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ministry of Tourism',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Republic of Sudan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Hotel Oversight Division',
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
                      '/ministry-dashboard',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.building,
                      'Hotel Registry',
                      Colors.green,
                      '/hotel-registry',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.users,
                      'Users Management',
                      Colors.purple,
                      '/ministry-users',
                    ),
                    _buildMenuItem(
                      FontAwesomeIcons.fileAlt,
                      'Reports & Analytics',
                      Colors.teal,
                      '/ministry-reports',
                    ),

                    // 💰 Updated Revenue & Taxes item
                    _buildMenuItem(
                      FontAwesomeIcons.dollarSign,
                      'Revenue & Taxes',
                      Colors.orange,
                      null,
                      onTap: _showRevenueDialog,
                    ),

                    _buildMenuItem(
                      FontAwesomeIcons.history,
                      'Activities',
                      Colors.cyan,
                      '/ministry-activities',
                    ),

                    // ⚙️ Updated Settings item
                    _buildMenuItem(
                      FontAwesomeIcons.cog,
                      'Settings',
                      Colors.grey,
                      null,
                      onTap: _showSettingsDialog,
                    ),
                  ],
                ),
              ),

              // Logout button
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

  // 🔹 Updated _buildMenuItem supporting optional onTap
  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color iconColor,
    String? route, {
    VoidCallback? onTap,
  }) {
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
          if (onTap != null) {
            onTap(); // Custom action (shows dialog)
          } else if (route != null) {
            final currentRoute = ModalRoute.of(context)?.settings.name;
            if (currentRoute != route) {
              if (route == '/ministry-dashboard') {
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
