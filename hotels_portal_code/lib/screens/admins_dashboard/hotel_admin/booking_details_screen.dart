import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool isSidebarOpen = false;
  Guest? _guest;
  Room? _room;
  bool _isLoadingGuest = true;
  bool _isLoadingRoom = true;

  @override
  void initState() {
    super.initState();
    _fetchGuestDetails();
    _fetchRoomDetails();
  }

  Future<void> _fetchGuestDetails() async {
    try {
      final guestId = widget.booking.guestId.id;
      final guestData = await GuestService().getGuest(guestId);
      if (mounted) {
        setState(() {
          _guest = guestData;
          _isLoadingGuest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGuest = false;
        });
        print("Failed to load guest details: $e");
      }
    }
  }

  Future<void> _fetchRoomDetails() async {
    try {
      // Assuming you have a method in HotelService to get a single room.
      // If not, this is a placeholder for that logic.
      // For now, let's assume a simple fetch.
      final roomDoc = await widget.booking.roomId
          .get(); // Directly get from DocumentReference
      if (mounted) {
        if (roomDoc.exists) {
          setState(() {
            _room = Room.fromMap(roomDoc.data() as Map<String, dynamic>);
            _isLoadingRoom = false;
          });
        } else {
          setState(() {
            _isLoadingRoom = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoom = false;
        });
        print("Failed to load room details: $e");
      }
    }
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
                    const Header(title: "Booking Details"),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confirmation Code: ${widget.booking.confirmationCode}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildGuestDetailsCard(),
                                      const SizedBox(height: 24),
                                      _buildBookingInfoCard(),
                                      const SizedBox(height: 24),
                                      _buildRoomDetailsCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _buildPaymentSummaryCard(),
                                ),
                              ],
                            ),
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
          );
        },
      ),
    );
  }

  Widget _buildGuestDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guest Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const Divider(height: 24),
            if (_isLoadingGuest)
              const Center(child: CircularProgressIndicator())
            else if (_guest == null)
              const Text('Could not load guest details.')
            else
              Column(
                children: [
                  _buildDetailRow('Name:', '${_guest!.fName} ${_guest!.lName}'),
                  _buildDetailRow('Email:', _guest!.email),
                  _buildDetailRow('Phone:', _guest!.phone ?? 'N/A'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Check-in Date:',
              DateFormat('MMM dd, yyyy').format(widget.booking.checkInDate),
            ),
            _buildDetailRow(
              'Check-out Date:',
              DateFormat('MMM dd, yyyy').format(widget.booking.checkOutDate),
            ),
            _buildDetailRow(
              'Number of Rooms:',
              widget.booking.roomsQuantity.toString(),
            ),
            _buildDetailRow(
              'Guests:',
              '${widget.booking.adultsGuests} Adults, ${widget.booking.childrenGuests ?? 0} Children',
            ),
            _buildDetailRow(
              'Special Requests:',
              widget.booking.specialRequests ?? 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const Divider(height: 24),
            if (_isLoadingRoom)
              const Center(child: CircularProgressIndicator())
            else if (_room == null)
              const Text('Could not load room details.')
            else
              Column(
                children: [
                  _buildDetailRow('Room Type:', _room!.roomType),
                  _buildDetailRow(
                    'Price Per Night:',
                    '\$${_room!.pricePerNight.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Max Guests:',
                    "${_room!.maxAdults} Adults, ${_room!.maxChildren} Children",
                  ),
                  _buildDetailRow('Amenities:', _room!.amenities.join(', ')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Total Amount:',
              '\$${widget.booking.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            _buildPaymentStatus(widget.booking.bookingStatus),
            const SizedBox(height: 16),
            _buildStatusChip(widget.booking.bookingStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(String bookingStatus) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (bookingStatus.toLowerCase()) {
      case 'checked_in':
      case 'completed':
        statusText = 'Paid';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusText = 'Not Applicable';
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        break;
      case 'pending':
      case 'confirmed':
      default:
        statusText = 'Not Paid';
        statusColor = Colors.orange;
        statusIcon = Icons.credit_card;
        break;
    }

    return _buildDetailRow(
      'Payment Status:',
      statusText,
      icon: statusIcon,
      valueColor: statusColor,
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: valueColor ?? Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
