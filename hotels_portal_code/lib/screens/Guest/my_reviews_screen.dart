import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/review.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/widgets/account_nav_bar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  _MyReviewsScreenState createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  String _selectedTab = 'My Reviews';
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final guestId = authProvider.currentGuest?.guestId;

    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final guestService = GuestService();
      final reviews = await guestService.getGuestReviews(guestId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load reviews: $e')));
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
        Navigator.pushNamed(context, '/my_bookings');
        break;
      case 'My Reviews':
        // Already here
        break;
      case 'Notifications':
        Navigator.pushNamed(context, '/notifications');
        break;
      case 'Settings':
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: GuestSidebar(),
      body: SafeArea(
        child: Column(
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
                  Expanded(
                    child: Center(
                      child: Text(
                        'My Reviews',
                        style: const TextStyle(
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFFFFF),
                    ),
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
                            'Your Reviews',
                            style: TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? _buildPlaceholders()
                              : _reviews.isEmpty
                              ? _buildEmptyState()
                              : _buildReviewList(),
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
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _ReviewCard(review: review);
      },
    );
  }

  Widget _buildPlaceholders() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => const _ReviewCardPlaceholder(),
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
        'No reviews yet. Share your experiences after a completed stay!',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

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
          Text(
            review
                .hotelName, // Assuming you'll want to display Hotel Name here later
            style: const TextStyle(
              color: Color(0xFF004D40),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.starRate ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 8),
          if (review.review != null && review.review!.isNotEmpty)
            Text(review.review!, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            'Reviewed on ${DateFormat('MMM dd, yyyy').format(review.createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReviewCardPlaceholder extends StatelessWidget {
  const _ReviewCardPlaceholder();

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
          _buildPlaceholder(width: 120, height: 16),
          const SizedBox(height: 10),
          _buildPlaceholder(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          _buildPlaceholder(width: 250, height: 14),
          const SizedBox(height: 10),
          _buildPlaceholder(width: 100, height: 12),
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
