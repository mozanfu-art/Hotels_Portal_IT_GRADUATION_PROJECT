import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/search_provider.dart';
import 'package:hotel_booking_app/services/search_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Hotel> _hotels = [];
  bool _isLoading = true;

  // Filter state variables
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  int? _minRating;
  int? _maxRating;
  final List<String> _selectedAmenities = [];
  final Set<String> _availableCities = {};
  final Set<String> _availableAmenities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHotels();
    });
  }

  Future<void> _fetchHotels() async {
    setState(() => _isLoading = true);
    try {
      final searchService = SearchService();
      final searchProvider = Provider.of<SearchProvider>(
        context,
        listen: false,
      );

      final filters = SearchFilters(
        location: searchProvider.selectedState,
        city: _selectedCity,
        checkInDate: searchProvider.checkInDate,
        checkOutDate: searchProvider.checkOutDate,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minStarRating: _minRating,
        maxStarRating: _maxRating,
        amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
      );

      final hotels = await searchService.searchHotels(filters: filters);
      if (mounted) {
        setState(() {
          _hotels = hotels;
          _isLoading = false;
          _availableCities.clear();
          _availableAmenities.clear();
          for (var hotel in hotels) {
            _availableCities.add(hotel.hotelCity);
            _availableAmenities.addAll(hotel.amenities);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load hotels: $e')));
      }
    }
  }

  void _navigateToHotelInfo(Hotel hotel) {
    Navigator.pushNamed(context, '/hotel_info', arguments: hotel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: const GuestSidebar(),
      endDrawer: _buildFilterSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF004D40),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isLoading)
                            Text(
                              '${_hotels.length} hotels found',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Available Hotels Header & Filter Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Hotels',
                            style: TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.filter_list,
                                color: Color(0xFF004D40),
                              ),
                              onPressed: () =>
                                  Scaffold.of(context).openEndDrawer(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading, Empty, or List State
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_hotels.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No hotels found for your criteria.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final hotel = _hotels[index];
                          return _buildHotelCard(hotel);
                        }, childCount: _hotels.length),
                      ),
                    ),

                  // Sticky Footer
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

  Widget _buildHotelCard(Hotel hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hotel.imageURLs.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    hotel.imageURLs.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.hotel, color: Colors.grey),
                    ),
                  ),
                )
              : Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.hotel, color: Colors.grey),
                ),
          const SizedBox(height: 8),
          Text(
            hotel.hotelName,
            style: const TextStyle(
              color: Color(0xFF004D40),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hotel.hotelAddress,
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                hotel.starRate.toStringAsFixed(1),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hotel.hotelDescription,
            style: TextStyle(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToHotelInfo(hotel),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF004D40),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF004D40)),
              child: const Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Filter Hotels',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Filter Content
            Expanded(
              child: Container(
                color: const Color(0xFF004D40),
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City Filter
                      const Text(
                        'City',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedCity,
                        hint: const Text(
                          'Select city',
                          style: TextStyle(color: Colors.white),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF004D40),
                        style: const TextStyle(color: Colors.white),
                        items: _availableCities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(
                              city,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price Range
                      const Text(
                        'Price Range (per night)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
                                labelStyle: TextStyle(color: Colors.white),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _minPrice = double.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
                                labelStyle: TextStyle(color: Colors.white),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _maxPrice = double.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rating Filter
                      const Text(
                        'Star Rating',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              value: _minRating,
                              hint: const Text(
                                'Min Stars',
                                style: TextStyle(color: Colors.white),
                              ),
                              isExpanded: true,
                              dropdownColor: const Color(0xFF004D40),
                              style: const TextStyle(color: Colors.white),
                              items: List.generate(5, (index) => index + 1).map(
                                (rating) {
                                  return DropdownMenuItem<int>(
                                    value: rating,
                                    child: Text(
                                      '$rating+ stars',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _minRating = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _maxRating,
                              hint: const Text(
                                'Max Stars',
                                style: TextStyle(color: Colors.white),
                              ),
                              isExpanded: true,
                              dropdownColor: const Color(0xFF004D40),
                              style: const TextStyle(color: Colors.white),
                              items: List.generate(5, (index) => index + 1).map(
                                (rating) {
                                  return DropdownMenuItem<int>(
                                    value: rating,
                                    child: Text(
                                      '$rating stars',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _maxRating = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amenities Filter
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: _availableAmenities.map((amenity) {
                          return FilterChip(
                            label: Text(
                              amenity,
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: _selectedAmenities.contains(amenity),
                            backgroundColor: const Color(0xFF004D40),
                            selectedColor: Colors.white.withOpacity(0.2),
                            checkmarkColor: Colors.white,
                            side: BorderSide.none,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAmenities.add(amenity);
                                } else {
                                  _selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer Buttons
            Container(
              color: const Color(0xFF004D40),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Clear filters
                        setState(() {
                          _selectedCity = null;
                          _minPrice = null;
                          _maxPrice = null;
                          _minRating = null;
                          _maxRating = null;
                          _selectedAmenities.clear();
                        });
                        Navigator.of(context).pop(); // Close drawer
                        _fetchHotels(); // Refetch with cleared filters
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close drawer
                        _fetchHotels(); // Refetch with new filters
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF004D40),
                      ),
                      child: const Text('Apply'),
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
}
