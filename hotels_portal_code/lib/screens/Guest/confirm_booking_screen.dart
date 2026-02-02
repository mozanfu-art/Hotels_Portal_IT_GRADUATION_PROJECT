import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/utils/index.dart';
import 'package:hotel_booking_app/utils/globals.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen({super.key});

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  Map<String, dynamic> args = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final Guest? currentUser = authProvider.currentGuest;

    if (currentUser != null) {
      firstNameController.text = currentUser.fName;
      lastNameController.text = currentUser.lName;
      emailController.text = currentUser.email;
      phoneController.text = currentUser.phone ?? 'Not provided';
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _generateConfirmationCode(String hotelName) {
    final random = Random();
    final hotelCode = hotelName.length >= 3
        ? hotelName.substring(0, 3).toUpperCase()
        : 'HTL';
    final randomNumber = random.nextInt(9000) + 1000;
    return '$hotelCode-${DateTime.now().year}-$randomNumber';
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    final guest = authProvider.currentGuest;
    if (guest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final updatedFirstName = firstNameController.text.trim();
      final updatedLastName = lastNameController.text.trim();
      final updatedPhone = phoneController.text.trim();

      final Map<String, dynamic> guestUpdates = {};
      if (updatedFirstName != guest.fName) {
        guestUpdates['FName'] = updatedFirstName;
      }
      if (updatedLastName != guest.lName) {
        guestUpdates['LName'] = updatedLastName;
      }
      if (updatedPhone != guest.phone) {
        guestUpdates['phone'] = updatedPhone;
      }

      if (guestUpdates.isNotEmpty) {
        final guestService = GuestService();
        await guestService.updateGuest(guest.guestId, guestUpdates);
        await authProvider.refreshGuestData();
      }

      final hotel = Hotel.fromJson(args['hotel'] as Map<String, dynamic>);
      final room = Room.fromMap(args['selectedRoom'] as Map<String, dynamic>);
      final checkIn = args['checkInDate'] as DateTime;
      final checkOut = args['checkOutDate'] as DateTime;
      final nights = checkOut.difference(checkIn).inDays;
      final totalCost =
          (room.pricePerNight * nights) + 150.0; // Calculate total cost

      final bookingId = FirebaseFirestore.instance
          .collection('bookings')
          .doc()
          .id;
      final confirmationCode = _generateConfirmationCode(hotel.hotelName);

      final newBooking = Booking(
        bookingId: bookingId,
        guestId: FirebaseFirestore.instance
            .collection('guests')
            .doc(guest.guestId),
        hotelId: FirebaseFirestore.instance
            .collection('hotels')
            .doc(hotel.hotelId),
        roomId: FirebaseFirestore.instance.collection('rooms').doc(room.roomId),
        checkInDate: checkIn,
        checkOutDate: checkOut,
        adultsGuests: args['adults'] as int,
        childrenGuests: args['children'] as int,
        roomType: room.roomType,
        roomsQuantity: 1,
        totalAmount: totalCost,
        bookingStatus: 'confirmed',
        confirmationCode: confirmationCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        guestName: '$updatedFirstName $updatedLastName',
        hotelName: hotel.hotelName,
        hotelCity: hotel.hotelCity,
        hotelState: hotel.hotelState,
      );
      final guestId = authProvider.currentGuest!.guestId;
      final guestName =
          '${authProvider.currentGuest!.fName} ${authProvider.currentGuest!.lName}';
      final createdBookingId = await hotelProvider.createBooking(
        newBooking,
        guestId,
        guestName,
      );

      if (createdBookingId != null) {
        showNotification(
          'Booking Confirmed',
          'Your booking has been confirmed successfully.',
          flutterLocalNotificationsPlugin,
        );

        Navigator.pushReplacementNamed(
          context,
          '/booking_confirmed',
          arguments: {
            ...args,
            'bookingRef': confirmationCode,
            'email': guest.email,
            'totalCost': totalCost,
          },
        );
      } else {
        throw Exception('Failed to get booking ID.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = Hotel.fromJson(args['hotel'] as Map<String, dynamic>);
    final room = Room.fromMap(args['selectedRoom'] as Map<String, dynamic>);
    final checkIn = args['checkInDate'] as DateTime;
    final checkOut = args['checkOutDate'] as DateTime;
    final nights = checkOut.difference(checkIn).inDays;
    final adults = args['adults'] as int;
    final children = args['children'] as int;
    final roomCost = room.pricePerNight * nights;
    const taxesAndFees = 0.0;
    final totalCost = roomCost + taxesAndFees;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm your Booking'),
        backgroundColor: const Color(0xFF004D40),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please review your details to finalize the reservation.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // User Details Form
                  _buildSection(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildEditableTextField(
                                'First Name',
                                firstNameController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildEditableTextField(
                                'Last Name',
                                lastNameController,
                              ),
                            ),
                          ],
                        ),
                        _buildEditableTextField(
                          'Email',
                          emailController,
                          readOnly: false,
                        ),
                        _buildEditableTextField(
                          'Phone Number',
                          phoneController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reservation Summary
                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reservation Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          'Hotel',
                          '${hotel.hotelName}, ${hotel.hotelCity}',
                        ),
                        _buildSummaryRow('Room Type', room.roomType),
                        _buildSummaryRow(
                          'Check-in',
                          DateFormat('MMM dd, yyyy').format(checkIn),
                        ),
                        _buildSummaryRow(
                          'Check-out',
                          DateFormat('MMM dd, yyyy').format(checkOut),
                        ),
                        _buildSummaryRow(
                          'Guests',
                          '$adults Adults${children > 0 ? ', $children Children' : ''}',
                        ),
                        _buildSummaryRow('Duration', '$nights nights'),
                        const Divider(),
                        _buildSummaryRow(
                          'Room Cost',
                          '\$${roomCost.toStringAsFixed(2)}',
                        ),
                        _buildSummaryRow(
                          'Taxes & Fees',
                          '\$${taxesAndFees.toStringAsFixed(2)}',
                        ),
                        const Divider(),
                        _buildSummaryRow(
                          'Total',
                          '\$${totalCost.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No payment is required at this stage. You will pay at the hotel.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Booking'),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Spacer(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: const Footer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : Colors.transparent,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
