import 'package:flutter/material.dart';
import 'package:hotel_booking_app/providers/booking_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking_app/models/booking.dart';

class BookingsTable extends StatefulWidget {
  const BookingsTable({super.key});

  @override
  State<BookingsTable> createState() => _BookingsTableState();
}

class _BookingsTableState extends State<BookingsTable> {
  String selectedStatus = 'All Status';
  String searchQuery = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchAllBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004d40),
                  ),
                ),
                const Spacer(),
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search bookings...',
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
                const SizedBox(width: 16),
                // Status filter
                DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: selectedStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                  items:
                      [
                            'All Status',
                            'confirmed',
                            'pending',
                            'completed',
                            'cancelled',
                          ]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status[0].toUpperCase() + status.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                  underline: const SizedBox(),
                  style: TextStyle(color: const Color(0xFF004d40)),
                ),
              ],
            ),
          ),
          // Table
          SizedBox(
            width: double.infinity,
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                if (bookingProvider.isLoading) {
                  return const _BookingTablePlaceholder();
                }

                if (bookingProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error: ${bookingProvider.error}'),
                    ),
                  );
                }

                final filteredBookings = bookingProvider.bookings.where((
                  booking,
                ) {
                  final statusMatch =
                      selectedStatus == 'All Status' ||
                      booking.bookingStatus.toLowerCase() ==
                          selectedStatus.toLowerCase();
                  final searchMatch =
                      searchQuery.isEmpty ||
                      booking.guestName.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      booking.hotelName.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ||
                      booking.bookingId.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      );
                  return statusMatch && searchMatch;
                }).toList();

                final bookingDataSource = BookingData(
                  bookings: filteredBookings,
                  context: context,
                );

                return PaginatedDataTable(
                  header: const Text(''), // Header is handled above
                  rowsPerPage: _rowsPerPage,
                  onRowsPerPageChanged: (value) {
                    setState(() {
                      _rowsPerPage = value!;
                    });
                  },
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  source: bookingDataSource,
                  columns: [
                    DataColumn(label: Text('Guest Name'), onSort: _onSort),
                    DataColumn(label: Text('Hotel'), onSort: _onSort),
                    DataColumn(
                      label: Text('Check-in'),
                      numeric: true,
                      onSort: _onSort,
                    ),
                    DataColumn(label: Text('Status'), onSort: _onSort),
                    DataColumn(
                      label: Text('Amount'),
                      numeric: true,
                      onSort: _onSort,
                    ),
                    DataColumn(label: Text('Actions')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    // Note: Sorting logic needs to be implemented within the DataTableSource
    // or applied to the list before passing it to the source.
    // This is a placeholder for now.
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

class BookingData extends DataTableSource {
  final List<Booking> bookings;
  final BuildContext context;

  BookingData({required this.bookings, required this.context});

  @override
  DataRow getRow(int index) {
    final booking = bookings[index];
    return DataRow(
      cells: [
        DataCell(Text(booking.guestName)),
        DataCell(Text(booking.hotelName)),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(booking.checkInDate))),
        DataCell(_buildStatusChip(booking.bookingStatus)),
        DataCell(Text('\$${booking.totalAmount.toStringAsFixed(2)}')),
        DataCell(
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/ministry-booking-details',
                    arguments: booking,
                  );
                },
                icon: Icon(Icons.visibility, color: Colors.blue.shade600),
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => bookings.length;

  @override
  int get selectedRowCount => 0;

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'pending':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        break;
      case 'completed':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'cancelled':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _BookingTablePlaceholder extends StatelessWidget {
  const _BookingTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(5, (index) => const _PlaceholderRow()),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildPlaceholderBox(150),
            const Spacer(),
            _buildPlaceholderBox(120),
            const Spacer(),
            _buildPlaceholderBox(100),
            const Spacer(),
            _buildPlaceholderBox(80),
            const Spacer(),
            _buildPlaceholderBox(60),
            const Spacer(),
            _buildPlaceholderBox(80),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox(double width) {
    return Container(
      height: 20,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
