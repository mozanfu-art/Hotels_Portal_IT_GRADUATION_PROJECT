import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/booking.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/services/booking_service.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/widgets/account_nav_bar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _selectedTab = 'My Bookings';
  List<Booking> _bookings = [];
  Set<String> _reviewedBookingIds = {};
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final guestId = authProvider.currentGuest?.guestId;

    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final guestService = GuestService();
    // Fetch bookings and reviews in parallel for efficiency
    final bookingsFuture = guestService.getGuestBookingHistory(guestId);
    final reviewsFuture = guestService.getGuestReviews(guestId);

    try {
      final results = await Future.wait([bookingsFuture, reviewsFuture]);
      final bookings = results[0] as List<Booking>;
      final reviews = results[1] as List<Review>;

      // Create a set of booking IDs that have already been reviewed
      final reviewedBookingIds = reviews.map((r) => r.bookingId).toSet();

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _reviewedBookingIds = reviewedBookingIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final guestId = authProvider.currentGuest!.guestId;
        final guestName =
            '${authProvider.currentGuest!.fName} ${authProvider.currentGuest!.lName}';
        final bookingService = BookingService();
        await bookingService.cancelBooking(
          booking.bookingId,
          guestId,
          guestName,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchData(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    switch (tab) {
      case 'Profile':
        Navigator.pushNamed(context, '/my_account');
        break;
      case 'My Bookings':
        // Already here
        break;
      case 'My Reviews':
        Navigator.pushNamed(context, '/my_reviews');
        break;
      case 'Notifications':
        Navigator.pushNamed(context, '/notifications');
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _showReviewDialog(Booking booking) {
    int rating = 0;
    final commentController = TextEditingController();
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Leave a Review for ${booking.hotelName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rate your experience:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write your review here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text("Post as Anonymous"),
                      value: isAnonymous,
                      onChanged: (newValue) {
                        setDialogState(() {
                          isAnonymous = newValue!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (rating > 0 && commentController.text.isNotEmpty) {
                      _submitReview(
                        booking,
                        rating,
                        commentController.text,
                        isAnonymous,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a rating and comment.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(
    Booking booking,
    int rating,
    String comment,
    bool isAnonymous,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final guest = authProvider.currentGuest;
    if (guest == null) return;

    final guestService = GuestService();
    final reviewerName = isAnonymous
        ? 'Anonymous'
        : '${guest.fName} ${guest.lName}';

    final newReview = Review(
      reviewId: FirebaseFirestore.instance.collection('reviews').doc().id,
      guestId: guest.guestId,
      hotelId: booking.hotelId.id,
      bookingId: booking.bookingId,
      hotelName: booking.hotelName,
      guestName: reviewerName,
      starRate: rating.toDouble(),
      review: comment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await guestService.addReview(newReview);
      setState(() {
        _reviewedBookingIds.add(booking.bookingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: const GuestSidebar(),
      body: Column(
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
                      'My Bookings',
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
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
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
                          'Your Bookings',
                          style: TextStyle(
                            color: Color(0xFF004D40),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? _buildPlaceholders()
                            : _bookings.isEmpty
                            ? _buildEmptyState()
                            : _buildBookingList(),
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
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final canReview =
            booking.bookingStatus.toLowerCase() == 'completed' &&
            !_reviewedBookingIds.contains(booking.bookingId);
        return _BookingCard(
          booking: booking,
          canReview: canReview,
          onReviewPressed: () => _showReviewDialog(booking),
          onCancelPressed: () => _cancelBooking(booking),
        );
      },
    );
  }

  Widget _buildPlaceholders() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => const _BookingCardPlaceholder(),
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
        'No bookings yet. Start booking your perfect stay!',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool canReview;
  final VoidCallback onReviewPressed;
  final VoidCallback onCancelPressed;

  const _BookingCard({
    required this.booking,
    required this.canReview,
    required this.onReviewPressed,
    required this.onCancelPressed,
  });

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

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            'Payment: $statusText',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            statusText == 'Not Paid' ? '(Pay at check-in)' : '',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.hotelName,
                  style: const TextStyle(
                    color: Color(0xFF004D40),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check-in: ${DateFormat('MMM dd, yyyy').format(booking.checkInDate)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            'Check-out: ${DateFormat('MMM dd, yyyy').format(booking.checkOutDate)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            'Guests: ${booking.adultsGuests} adults, ${booking.childrenGuests ?? 0} children',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            'Total: \$${booking.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          _buildPaymentStatus(booking.bookingStatus),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canReview)
                ElevatedButton(
                  onPressed: onReviewPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Leave a Review'),
                ),
              if (booking.bookingStatus.toLowerCase() == 'confirmed' ||
                  booking.bookingStatus.toLowerCase() == 'pending')
                TextButton(
                  onPressed: onCancelPressed,
                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingCardPlaceholder extends StatelessWidget {
  const _BookingCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceholder(width: 200, height: 20),
          const SizedBox(height: 12),
          _buildPlaceholder(width: 150, height: 14),
          const SizedBox(height: 6),
          _buildPlaceholder(width: 150, height: 14),
          const SizedBox(height: 6),
          _buildPlaceholder(width: 180, height: 14),
          const SizedBox(height: 6),
          _buildPlaceholder(width: 100, height: 14),
        ],
      ),
    );
  }

  Widget _buildPlaceholder({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
