import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/notification.dart' as model;
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/services/notification_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MinistryNotificationsScreen extends StatefulWidget {
  const MinistryNotificationsScreen({super.key});

  @override
  State<MinistryNotificationsScreen> createState() =>
      _MinistryNotificationsScreenState();
}

class _MinistryNotificationsScreenState
    extends State<MinistryNotificationsScreen> {
  bool isSidebarOpen = false;
  Stream<List<model.Notification>>? _notificationsStream;
  final NotificationService _notificationService = NotificationService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the stream here to ensure context is available
    if (_notificationsStream == null) {
      final adminId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentAdmin?.adminId;
      if (adminId != null) {
        setState(() {
          _notificationsStream = _notificationService
              .getAdminNotificationsStream(adminId);
        });
      }
    }
  }

  Future<void> _markAsRead(model.Notification notification) async {
    //
    final adminId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentAdmin?.adminId;
    if (adminId != null && !notification.read) {
      try {
        await _notificationService.markAdminNotificationAsRead(
          adminId,
          notification.notificationId,
        );
      } catch (e) {
        // Handle error if needed, e.g., show a snackbar
        print("Failed to mark notification as read: $e");
      }
    }
    // Optional: Navigate to a relevant screen based on notification type
    // if (notification.bookingId != null) { ... }
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
              MinistryAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
              ),
              Expanded(
                child: Column(
                  children: [
                    MinistryAdminHeader(title: "Notifications"),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Notifications',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF004d40),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
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
                                          child: Text(
                                            'Error: ${snapshot.error}',
                                          ),
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'You have no notifications.',
                                          ),
                                        );
                                      }

                                      final notifications = snapshot.data!;
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: notifications.length,
                                        itemBuilder: (context, index) {
                                          final notification =
                                              notifications[index];
                                          return _buildNotificationCard(
                                            notification,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Footer(),
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

  Widget _buildNotificationCard(model.Notification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'booking':
        icon = FontAwesomeIcons.calendarCheck;
        iconColor = Colors.blue;
        break;
      case 'report':
        icon = FontAwesomeIcons.fileAlt;
        iconColor = Colors.green;
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
}
