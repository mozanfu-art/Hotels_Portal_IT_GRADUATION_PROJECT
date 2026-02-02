import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

class HotelInfoScreen extends StatefulWidget {
  final Hotel hotel;

  const HotelInfoScreen({super.key, required this.hotel});

  @override
  _HotelInfoScreenState createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      hotelProvider.loadRooms(widget.hotel.hotelId);
      hotelProvider.loadReviews(widget.hotel.hotelId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFavorite(AuthProvider authProvider) {
    final isCurrentlyFavorite =
        authProvider.currentGuest?.favoriteHotelIds.contains(
          widget.hotel.hotelId,
        ) ??
        false;
    authProvider.toggleFavorite(widget.hotel.hotelId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !isCurrentlyFavorite
              ? 'Added to favorites'
              : 'Removed from favorites',
        ),
      ),
    );
  }

  void _bookNow() {
    Navigator.pushNamed(
      context,
      '/select_rooms',
      arguments: {
        'hotel': widget.hotel.toJson(),
        'checkInDate': DateTime.now(),
        'checkOutDate': DateTime.now().add(const Duration(days: 1)),
        'numberOfNights': 1,
        'numberOfGuests': 1,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final provider = Provider.of<HotelProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isFavorite =
        authProvider.currentGuest?.favoriteHotelIds.contains(hotel.hotelId) ??
        false;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              height: 60,
              color: const Color(0xFF004D40),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        hotel.hotelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(authProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating, Reviews
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${hotel.starRate}',
                            style: const TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${provider.reviews.length} reviews)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Hotel Images
                      SizedBox(
                        height: 200,
                        child: hotel.imageURLs.isEmpty
                            ? Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.hotel,
                                  color: Colors.grey[600],
                                  size: 80,
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: hotel.imageURLs.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 300,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        hotel.imageURLs[index],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (
                                              BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress,
                                            ) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Tab Bar
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: const Color(0xFF004D40),
                        labelColor: const Color(0xFF004D40),
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Rooms'),
                          Tab(text: 'Amenities'),
                          Tab(text: 'Reviews'),
                          Tab(text: 'Contact'),
                        ],
                      ),
                      // Tab Bar View
                      SizedBox(
                        height: 600,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Overview
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                hotel.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Rooms
                            Consumer<HotelProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading &&
                                    provider.rooms.isEmpty) {
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: 2,
                                    itemBuilder: (context, index) =>
                                        const _RoomPlaceholder(),
                                  );
                                }
                                if (provider.rooms.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No rooms found for this hotel.',
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: provider.rooms.length,
                                  itemBuilder: (context, index) {
                                    final room = provider.rooms[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (room.images.isNotEmpty)
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  room.images.first,
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          height: 150,
                                                          color:
                                                              Colors.grey[300],
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            const SizedBox(height: 12),
                                            Text(
                                              room.roomType,
                                              style: const TextStyle(
                                                color: Color(0xFF004D40),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Max Guests: ${room.maxAdults} Adults, ${room.maxChildren} Children',
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${room.pricePerNight.toStringAsFixed(2)} per night',
                                              style: const TextStyle(
                                                color: Color(0xFF004D40),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            // Amenities
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ListView(
                                children: hotel.amenities.map<Widget>((
                                  amenity,
                                ) {
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.check,
                                      color: Color(0xFF004D40),
                                    ),
                                    title: Text(amenity),
                                  );
                                }).toList(),
                              ),
                            ),
                            // Reviews
                            Consumer<HotelProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading &&
                                    provider.reviews.isEmpty) {
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16.0),
                                    itemCount: 4,
                                    itemBuilder: (context, index) =>
                                        const _ReviewPlaceholder(),
                                  );
                                }
                                if (provider.reviews.isEmpty) {
                                  return const Center(
                                    child: Text('No reviews yet.'),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: provider.reviews.length,
                                  itemBuilder: (context, index) {
                                    final review = provider.reviews[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey[200],
                                        child: Text(
                                          review.guestName.isNotEmpty
                                              ? review.guestName[0]
                                              : 'G',
                                        ),
                                      ),
                                      title: Text(
                                        review.guestName,
                                        style: const TextStyle(
                                          color: Color(0xFF004D40),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                i < review.starRate
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          if (review.review != null &&
                                              review.review!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                review.review!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            // Contact
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contact Information',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF004D40),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          hotel.hotelAddress,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Color(0xFF004D40),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hotel.hotelPhone ?? 'N/A',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        color: Color(0xFF004D40),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        hotel.hotelEmail ?? 'N/A',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Book Now Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _bookNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

// Placeholder for a review item
class _ReviewPlaceholder extends StatelessWidget {
  const _ReviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: Colors.grey[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(width: 80, height: 14, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Container(width: 200, height: 14, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for a room item
class _RoomPlaceholder extends StatelessWidget {
  const _RoomPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Container(width: 200, height: 20, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 150, height: 16, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 100, height: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
