import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const Header({
    super.key,
    this.title = 'Dashboard',
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final admin = authProvider.currentAdmin;

    final String displayName = admin != null
        ? '${admin.fName} ${admin.lName}'
        : 'Admin User';
    final String initials =
        admin != null && admin.fName.isNotEmpty && admin.lName.isNotEmpty
        ? '${admin.fName[0]}${admin.lName[0]}'
        : 'A';

    return Container(
      color: const Color(0xFF004d40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Search
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF004d40)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notification
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/hotel-notifications');
                },
                icon: FaIcon(FontAwesomeIcons.bell, color: Colors.white),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Profile
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthProvider>(context, listen: false).signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/hotel-admin-profile');
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/hotel-admin-settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF004d40),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          if (showBackButton) ...[
            const SizedBox(width: 16),
            // Back button fixed to the far right corner after dropdown
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
            ),
          ],
        ],
      ),
    );
  }
}
