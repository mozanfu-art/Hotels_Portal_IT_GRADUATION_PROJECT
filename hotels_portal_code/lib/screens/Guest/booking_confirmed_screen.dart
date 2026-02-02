import 'package:flutter/material.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:intl/intl.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key});

  /// Helper to safely format dates, returning 'N/A' if the date is null.
  String _formatDate(DateTime? date) {
    if (date != null) {
      return DateFormat('MMM dd, yyyy').format(date);
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Safely retrieve and cast arguments from the previous screen.
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    // Extract all necessary data with null-safe fallbacks.
    final String bookingRef = args['bookingRef'] as String? ?? 'N/A';
    final String email = args['email'] as String? ?? 'your email';
    final hotelData = args['hotel'] as Map<String, dynamic>? ?? {};
    final roomData = args['selectedRoom'] as Map<String, dynamic>? ?? {};
    final checkInDate = args['checkInDate'] as DateTime?;
    final checkOutDate = args['checkOutDate'] as DateTime?;
    final nights = checkOutDate != null && checkInDate != null
        ? checkOutDate.difference(checkInDate).inDays
        : 0;
    final adults = args['adults'] as int? ?? 0;
    final children = args['children'] as int? ?? 0;
    final totalCost = args['totalCost'] as double? ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your reservation has been successfully confirmed. A confirmation email with all the details has been sent to $email.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildReferenceSection(bookingRef),
                  const SizedBox(height: 32),
                  _buildDetailsSection(
                    hotelName: hotelData['hotelName'] as String? ?? 'N/A',
                    roomType: roomData['roomType'] as String? ?? 'N/A',
                    checkIn: checkInDate,
                    checkOut: checkOutDate,
                    nights: nights,
                    guests:
                        '$adults adults${children > 0 ? ', $children children' : ''}',
                    totalPrice: totalCost,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to home and remove all previous routes from the stack.
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 16),
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
    );
  }

  /// Helper widget for displaying the booking reference number.
  Widget _buildReferenceSection(String bookingRef) {
    return Column(
      children: [
        const Text(
          'Booking Reference',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          bookingRef,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Color(0xFF004D40),
          ),
        ),
      ],
    );
  }

  /// Helper widget for displaying the detailed booking summary.
  Widget _buildDetailsSection({
    required String hotelName,
    required String roomType,
    required DateTime? checkIn,
    required DateTime? checkOut,
    required int nights,
    required String guests,
    required double totalPrice,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
          const Divider(height: 24),
          _buildDetailRow('Hotel:', hotelName),
          _buildDetailRow('Room:', roomType),
          _buildDetailRow('Check-in:', _formatDate(checkIn)),
          _buildDetailRow('Check-out:', _formatDate(checkOut)),
          _buildDetailRow('Nights:', nights.toString()),
          _buildDetailRow('Guests:', guests),
          const Divider(height: 24),
          _buildDetailRow(
            'Total Price:',
            '\$${totalPrice.toStringAsFixed(2)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  /// Helper widget for rendering a single row in the details section.
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF004D40),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
