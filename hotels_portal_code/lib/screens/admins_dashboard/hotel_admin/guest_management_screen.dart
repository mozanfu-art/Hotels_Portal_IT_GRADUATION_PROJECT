import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/user_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GuestManagementScreen extends StatefulWidget {
  const GuestManagementScreen({super.key});

  @override
  State<GuestManagementScreen> createState() => _GuestManagementScreenState();
}

class _GuestManagementScreenState extends State<GuestManagementScreen> {
  bool isSidebarOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hotelId != null) {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).fetchGuestsForHotel(authProvider.hotelId!);
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
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
                    if (!isMobile) const Header(title: "Guest History"),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Guest History',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF004d40),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Search Field
                                  TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, email, or phone...',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Consumer<UserProvider>(
                                      builder: (context, userProvider, child) {
                                        if (userProvider.isLoading) {
                                          return _buildPlaceholderTable();
                                        }
                                        if (userProvider.error != null) {
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                20.0,
                                              ),
                                              child: Text(
                                                'Error: ${userProvider.error}',
                                              ),
                                            ),
                                          );
                                        }

                                        // Filter the guests based on the search query
                                        final filteredGuests = userProvider
                                            .hotelGuests
                                            .where((guestData) {
                                              final guest =
                                                  guestData['guest'] as Guest;
                                              final fullName =
                                                  '${guest.fName} ${guest.lName}'
                                                      .toLowerCase();
                                              final email = guest.email
                                                  .toLowerCase();
                                              final phone =
                                                  guest.phone?.toLowerCase() ??
                                                  '';

                                              return fullName.contains(
                                                    _searchQuery,
                                                  ) ||
                                                  email.contains(
                                                    _searchQuery,
                                                  ) ||
                                                  phone.contains(_searchQuery);
                                            })
                                            .toList();

                                        if (filteredGuests.isEmpty) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Text('No guests found.'),
                                            ),
                                          );
                                        }

                                        return SizedBox(
                                          width: double.infinity,
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(label: Text('Name')),
                                              DataColumn(label: Text('Email')),
                                              DataColumn(label: Text('Phone')),
                                              DataColumn(
                                                label: Text('Total Bookings'),
                                              ),
                                              DataColumn(
                                                label: Text('Last Visit'),
                                              ),
                                            ],
                                            rows: filteredGuests.map((
                                              guestData,
                                            ) {
                                              final Guest guest =
                                                  guestData['guest'];
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      '${guest.fName} ${guest.lName}',
                                                    ),
                                                  ),
                                                  DataCell(Text(guest.email)),
                                                  DataCell(
                                                    Text(guest.phone ?? 'N/A'),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      guestData['bookingCount']
                                                          .toString(),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      DateFormat(
                                                        'MMM dd, yyyy',
                                                      ).format(
                                                        guestData['lastVisit'],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 24),
                                  const Footer(),
                                ],
                              ),
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

  Widget _buildPlaceholderTable() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(8, (index) => const _PlaceholderRow()),
        ),
      ),
    );
  }
}

class _PlaceholderRow extends StatefulWidget {
  const _PlaceholderRow();

  @override
  State<_PlaceholderRow> createState() => _PlaceholderRowState();
}

class _PlaceholderRowState extends State<_PlaceholderRow>
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
        height: 52, // Approx height of a DataRow
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildPlaceholderBox(height: 20)),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: _buildPlaceholderBox(height: 20)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildPlaceholderBox(height: 20)),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildPlaceholderBox(height: 20)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildPlaceholderBox(height: 20)),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildPlaceholderBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
