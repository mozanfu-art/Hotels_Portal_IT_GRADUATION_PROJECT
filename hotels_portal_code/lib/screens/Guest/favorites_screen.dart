import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    final favoriteIds = authProvider.currentGuest?.favoriteHotelIds ?? [];

    if (favoriteIds.isNotEmpty) {
      hotelProvider.fetchFavoriteHotels(favoriteIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: GuestSidebar(),
      body: Column(
        children: [
          // Header
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
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
          // Scrollable main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Favorite Hotels',
                    style: TextStyle(
                      color: Color(0xFF004D40),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer2<HotelProvider, AuthProvider>(
                      builder: (context, hotelProvider, authProvider, child) {
                        // Re-fetch if the list of favorite IDs changes
                        final favoriteIds =
                            authProvider.currentGuest?.favoriteHotelIds ?? [];
                        if (hotelProvider.favoriteHotels.length !=
                            favoriteIds.length) {
                          hotelProvider.fetchFavoriteHotels(favoriteIds);
                        }

                        if (hotelProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (hotelProvider.favoriteHotels.isEmpty) {
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
                              'No favorites yet. Add hotels to your favorites!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: hotelProvider.favoriteHotels.length,
                          itemBuilder: (context, index) {
                            final hotel = hotelProvider.favoriteHotels[index];
                            return _buildHotelCard(hotel, authProvider);
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  const Footer(),
                ],
              ),
            ),
          ),
          // Footer
          // Footer
        ],
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel, AuthProvider authProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/hotel_info', arguments: hotel);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hotel.imageURLs.isNotEmpty
                    ? Image.network(
                        hotel.imageURLs.first,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: Icon(Icons.hotel, color: Colors.grey[400]),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: Icon(Icons.hotel, color: Colors.grey[400]),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.hotelName,
                      style: const TextStyle(
                        color: Color(0xFF004D40),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel.hotelCity,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          hotel.starRate.toString(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  authProvider.toggleFavorite(hotel.hotelId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Removed ${hotel.hotelName} from favorites.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
