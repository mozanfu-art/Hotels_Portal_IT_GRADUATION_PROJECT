import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_bookings_table.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  bool isSidebarOpen = false;
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

                    const Header(title: "Bookings Management"),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bookings Management',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF004d40),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Filters and Search
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Search by Code or Guest Name...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedStatus,
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            labelText: 'Status',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          items:
                                              [
                                                    'All',
                                                    'pending',
                                                    'confirmed',
                                                    'checked_in',
                                                    'completed',
                                                    'cancelled',
                                                  ]
                                                  .map(
                                                    (
                                                      status,
                                                    ) => DropdownMenuItem(
                                                      value: status,
                                                      child: Text(
                                                        status[0]
                                                                .toUpperCase() +
                                                            status.substring(1),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedStatus = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  HotelBookingsTable(
                                    showActions: true,
                                    searchQuery: _searchQuery,
                                    statusFilter: _selectedStatus,
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
