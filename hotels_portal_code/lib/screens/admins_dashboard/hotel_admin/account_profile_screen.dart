import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
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
              HotelAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () {
                  setState(() {
                    isSidebarOpen = !isSidebarOpen;
                  });
                },
              ),
              Expanded(
                child: Column(
                  children: [
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
                    if (!isMobile) Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Account Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hotel Profile Section
                                Expanded(
                                  flex: 2,
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hotel Profile',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF004d40),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue:
                                                'Grand Khartoum Hotel',
                                            decoration: const InputDecoration(
                                              labelText: 'Hotel Name',
                                              border: OutlineInputBorder(),
                                            ),
                                            readOnly: true,
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue: 'Khartoum, Sudan',
                                            decoration: const InputDecoration(
                                              labelText: 'Location',
                                              border: OutlineInputBorder(),
                                            ),
                                            readOnly: true,
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue: '4.6',
                                            decoration: const InputDecoration(
                                              labelText: 'Rating',
                                              border: OutlineInputBorder(),
                                            ),
                                            readOnly: true,
                                          ),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue: 'LIC-2023-001',
                                            decoration: const InputDecoration(
                                              labelText: 'License Number',
                                              border: OutlineInputBorder(),
                                            ),
                                            readOnly: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Account Overview
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Account Overview',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF004d40,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              _OverviewItem(
                                                label: 'Occupancy',
                                                value: '85%',
                                                icon: FontAwesomeIcons.hotel,
                                              ),
                                              const SizedBox(height: 12),
                                              _OverviewItem(
                                                label: 'Rating',
                                                value: '4.6',
                                                icon: FontAwesomeIcons.star,
                                              ),
                                              const SizedBox(height: 12),
                                              _OverviewItem(
                                                label: 'Satisfaction',
                                                value: '92%',
                                                icon: FontAwesomeIcons.smile,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Recent Activity Log
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recent Activity Log',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF004d40),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: 5,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          leading: Icon(
                                            Icons.history,
                                            color: const Color(0xFF004d40),
                                          ),
                                          title: Text('Activity ${index + 1}'),
                                          subtitle: Text(
                                            'Description of activity ${index + 1}',
                                          ),
                                          trailing: Text('2 hours ago'),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Top Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.download),
                                  label: Text('Export'),
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
                                  icon: Icon(Icons.support),
                                  label: Text('Contact Support'),
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
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.save),
                                  label: Text('Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004d40),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
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
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF004d40).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(icon, color: const Color(0xFF004d40), size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF004d40),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
