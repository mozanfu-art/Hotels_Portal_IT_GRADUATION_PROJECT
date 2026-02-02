import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/notification.dart' as model;
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/widgets/account_nav_bar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedTab = 'Notifications';
  Stream<List<model.Notification>>? _notificationsStream;
  final GuestService _guestService = GuestService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notificationsStream == null) {
      final guestId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentGuest?.guestId;
      if (guestId != null) {
        setState(() {
          _notificationsStream = _guestService.getGuestNotificationsStream(
            guestId,
          );
        });
      }
    }
  }

  void _onTabSelected(String tab) {
    setState(() => _selectedTab = tab);
    switch (tab) {
      case 'Profile':
        Navigator.pushReplacementNamed(context, '/my_account');
        break;
      case 'My Bookings':
        Navigator.pushReplacementNamed(context, '/my_bookings');
        break;
      case 'My Reviews':
        Navigator.pushReplacementNamed(context, '/my_reviews');
        break;
      case 'Settings':
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 'Notifications':
        // Already on this screen
        break;
    }
  }

  Future<void> _markAsRead(model.Notification notification) async {
    final guestId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentGuest?.guestId;
    if (guestId != null && !notification.read) {
      try {
        await _guestService.markNotificationAsRead(
          guestId,
          notification.notificationId,
        );
      } catch (e) {
        print("Failed to mark notification as read: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: const GuestSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: const Color(0xFF004D40),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu icon
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  // Title
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Back arrow
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFFFFF),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            AccountNavBar(
              selectedTab: _selectedTab,
              onTabSelected: _onTabSelected,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Notifications',
                            style: TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<model.Notification>>(
                            stream: _notificationsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return _buildEmptyState();
                              }
                              final notifications = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  return _buildNotificationCard(notification);
                                },
                              );
                            },
                          ),
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
                          padding: const EdgeInsets.only(left: 20, right: 20),
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
    );
  }

  Widget _buildNotificationCard(model.Notification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'booking':
        icon = FontAwesomeIcons.calendarCheck;
        iconColor = Colors.blue;
        break;
      default:
        icon = FontAwesomeIcons.infoCircle;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: !notification.read ? Colors.blue.shade200 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => _markAsRead(notification),
        leading: FaIcon(icon, color: iconColor),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: !notification.read
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MMM dd, hh:mm a').format(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!notification.read)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Icon(Icons.circle, color: Colors.blue, size: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'You have no notifications yet.',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}
