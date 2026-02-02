import 'package:flutter/material.dart';

class AccountNavBar extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabSelected;

  const AccountNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      color: const Color(0xFFFFFFFF), // White background
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ), // Reduced padding for more space
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        physics:
            const BouncingScrollPhysics(), // Smooth, bouncy scroll (iOS-like)
        child: Row(
          children: [
            const SizedBox(width: 8), // Left padding for scroll start
            _buildNavTab('Profile', Icons.account_circle),
            _buildNavTab('My Bookings', Icons.book),
            _buildNavTab('My Reviews', Icons.rate_review),
            _buildNavTab('Notifications', Icons.notifications),
            _buildNavTab('Settings', Icons.settings),
            const SizedBox(width: 8), // Right padding for scroll end
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(String label, IconData icon) {
    final bool isSelected = selectedTab == label;
    return GestureDetector(
      onTap: () => onTabSelected(label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), // Space between tabs
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF004D40).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF004D40) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF004D40) : Colors.grey[600],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
