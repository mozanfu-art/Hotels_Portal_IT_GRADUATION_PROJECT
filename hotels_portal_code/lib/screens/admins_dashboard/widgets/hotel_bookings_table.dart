import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/booking_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HotelBookingsTable extends StatefulWidget {
  final bool showActions;
  final String? searchQuery;
  final String? statusFilter;

  const HotelBookingsTable({
    super.key,
    this.showActions = false,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  State<HotelBookingsTable> createState() => _HotelBookingsTableState();
}

class _HotelBookingsTableState extends State<HotelBookingsTable> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hotelId != null) {
        Provider.of<BookingProvider>(
          context,
          listen: false,
        ).fetchBookingsForHotel(authProvider.hotelId!);
      }
    });
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String bookingId,
    String action,
    String newStatus,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelId = authProvider.hotelId;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this booking?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (hotelId != null) {
                  await Provider.of<BookingProvider>(
                    context,
                    listen: false,
                  ).updateBookingStatus(bookingId, newStatus, hotelId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Booking has been ${newStatus.replaceAll('_', ' ')}.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  widget.showActions ? 'All Bookings' : 'Recent Bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004d40),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, child) {
                if (bookingProvider.isLoading) {
                  return const _HotelBookingsTablePlaceholder();
                }
                if (bookingProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error: ${bookingProvider.error}'),
                    ),
                  );
                }

                // Apply filters
                final filteredBookings = bookingProvider.hotelBookings.where((
                  booking,
                ) {
                  final statusMatch =
                      widget.statusFilter == null ||
                      widget.statusFilter == 'All' ||
                      booking.bookingStatus.toLowerCase() ==
                          widget.statusFilter!.toLowerCase();

                  final searchMatch =
                      widget.searchQuery == null ||
                      widget.searchQuery!.isEmpty ||
                      booking.confirmationCode.toLowerCase().contains(
                        widget.searchQuery!.toLowerCase(),
                      ) ||
                      booking.guestName.toLowerCase().contains(
                        widget.searchQuery!.toLowerCase(),
                      );

                  return statusMatch && searchMatch;
                }).toList();

                if (filteredBookings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No bookings found matching your criteria.'),
                    ),
                  );
                }

                final dataSource = _HotelBookingDataSource(
                  bookings: filteredBookings,
                  context: context,
                  showActions: widget.showActions,
                  onConfirm: (bookingId) => _showConfirmationDialog(
                    context,
                    bookingId,
                    'Confirm',
                    'confirmed',
                  ),
                  onCancel: (bookingId) => _showConfirmationDialog(
                    context,
                    bookingId,
                    'Cancel',
                    'cancelled',
                  ),
                  onCheckIn: (bookingId) => _showConfirmationDialog(
                    context,
                    bookingId,
                    'Check In',
                    'checked_in',
                  ),
                  onCheckOut: (bookingId) => _showConfirmationDialog(
                    context,
                    bookingId,
                    'Check Out',
                    'completed',
                  ),
                );
                return PaginatedDataTable(
                  columns: [
                    const DataColumn(label: Text('Guest Name')),
                    const DataColumn(label: Text('Confirmation Code')),
                    const DataColumn(label: Text('Check-in')),
                    const DataColumn(label: Text('Room Type')),
                    const DataColumn(label: Text('Status')),
                    if (widget.showActions)
                      const DataColumn(label: Text('Actions')),
                  ],
                  source: dataSource,
                  rowsPerPage: 5,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ... (Placeholder widgets remain the same) ...
class _HotelBookingsTablePlaceholder extends StatelessWidget {
  const _HotelBookingsTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPlaceholderBox(width: 120),
            _buildPlaceholderBox(width: 100),
            _buildPlaceholderBox(width: 80),
            _buildPlaceholderBox(width: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double width}) {
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

class _HotelBookingDataSource extends DataTableSource {
  final List<Booking> bookings;
  final BuildContext context;
  final bool showActions;
  final Function(String) onConfirm;
  final Function(String) onCancel;
  final Function(String) onCheckIn;
  final Function(String) onCheckOut;

  _HotelBookingDataSource({
    required this.bookings,
    required this.context,
    required this.showActions,
    required this.onConfirm,
    required this.onCancel,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  DataRow getRow(int index) {
    if (index >= bookings.length) {
      return const DataRow(cells: []);
    }
    final booking = bookings[index];

    List<Widget> actionButtons = [
      IconButton(
        tooltip: 'View Details',
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/hotel-booking-details',
            arguments: booking,
          );
        },
        icon: const Icon(Icons.visibility, color: Colors.blue),
      ),
    ];

    // UPDATED: Conditional action buttons based on status
    switch (booking.bookingStatus.toLowerCase()) {
      case 'pending':
        actionButtons.addAll([
          IconButton(
            tooltip: 'Confirm Booking',
            onPressed: () => onConfirm(booking.bookingId),
            icon: const Icon(Icons.check_circle, color: Colors.green),
          ),
          IconButton(
            tooltip: 'Cancel Booking',
            onPressed: () => onCancel(booking.bookingId),
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
        ]);
        break;
      case 'confirmed':
        actionButtons.addAll([
          IconButton(
            tooltip: 'Check In Guest',
            onPressed: () => onCheckIn(booking.bookingId),
            icon: const Icon(Icons.login, color: Colors.blueAccent),
          ),
          IconButton(
            tooltip: 'Cancel Booking',
            onPressed: () => onCancel(booking.bookingId),
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
        ]);
        break;
      case 'checked_in':
        actionButtons.add(
          IconButton(
            tooltip: 'Check Out Guest',
            onPressed: () => onCheckOut(booking.bookingId),
            icon: const Icon(Icons.logout, color: Colors.orange),
          ),
        );
        break;
    }

    return DataRow(
      cells: [
        DataCell(Text(booking.guestName)),
        DataCell(Text(booking.confirmationCode)),
        DataCell(Text(DateFormat('MMM dd, yyyy').format(booking.checkInDate))),
        DataCell(Text(booking.roomType)),
        DataCell(_buildStatusChip(booking.bookingStatus)),
        if (showActions)
          DataCell(
            Row(mainAxisSize: MainAxisSize.min, children: actionButtons),
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
      case 'checked_in':
        bgColor = Colors.deepPurple.shade100;
        textColor = Colors.deepPurple.shade800;
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
        status.toUpperCase().replaceAll('_', ' '),
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
