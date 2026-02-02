import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/booking_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/providers/search_provider.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_fetched) {
        Provider.of<HotelProvider>(
          context,
          listen: false,
        ).fetchFeaturedHotels();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final guest = authProvider.currentGuest;
        if (guest != null) {
          Provider.of<BookingProvider>(
            context,
            listen: false,
          ).fetchBookingsForUser(guest.guestId);
        }
        _fetched = true;
      }
    });
  }

  void _navigateToSearch() {
    Provider.of<SearchProvider>(context, listen: false).clear();
    Navigator.pushNamed(context, '/search');
  }

  void _navigateToHotelInfo(Hotel hotel) {
    Navigator.pushNamed(context, '/hotel_info', arguments: hotel);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final guest = authProvider.currentGuest;

    if (guest == null) {
      return Scaffold(
        backgroundColor: Color(0xFFFFFBF0),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004D40)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFFBF0),
      drawer: GuestSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: Color(0xFF004D40),
              padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome, ${guest.fName}',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'find your perfect stay in Sudan',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // search box
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'find your perfect hotel',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Search Thousands of Hotels across Sudan',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _navigateToSearch,
                                    icon: Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'search hotels',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF004D40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          Text(
                            'Featured Hotels',
                            style: TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 16),

                          Consumer<HotelProvider>(
                            builder: (context, hotelProvider, child) {
                              if (hotelProvider.isLoading &&
                                  hotelProvider.featuredHotels.isEmpty) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (hotelProvider.error != null) {
                                return Center(
                                  child: Text('Error: ${hotelProvider.error}'),
                                );
                              }
                              if (hotelProvider.featuredHotels.isEmpty) {
                                return Center(
                                  child: Text('No featured hotels available.'),
                                );
                              }
                              return Column(
                                children: hotelProvider.featuredHotels.map((
                                  hotel,
                                ) {
                                  return GestureDetector(
                                    onTap: () => _navigateToHotelInfo(hotel),
                                    child: Container(
                                      width: double.infinity,
                                      margin: EdgeInsets.only(bottom: 16),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: hotel.imageURLs.isNotEmpty
                                                ? Image.network(
                                                    hotel.imageURLs.first,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.hotel,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  hotel.hotelName,
                                                  style: TextStyle(
                                                    color: Color(0xFF004D40),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      color: Colors.grey[600],
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${hotel.hotelCity}, ${hotel.hotelState}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      hotel.starRate
                                                          .toStringAsFixed(1),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
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
                                  );
                                }).toList(),
                              );
                            },
                          ),

                          SizedBox(height: 24),

                          // ***********************
                          // POPULAR DESTINATIONS
                          // ***********************
                          Text(
                            'Popular Destinations',
                            style: TextStyle(
                              color: Color(0xFF004D40),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 16),

                          Column(
                            children: [
                              Row(
                                children: [
                                  // --------------------
                                  // KHARTOUM
                                  // --------------------
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => {
                                        Provider.of<SearchProvider>(
                                          context,
                                          listen: false,
                                        ).updateCriteria(
                                          state: 'Khartoum',
                                          checkIn: null,
                                          checkOut: null,
                                          adults: 1,
                                          children: 0,
                                        ),
                                        Navigator.pushNamed(
                                          context,
                                          '/search_results',
                                        ),
                                      },
                                      child: Container(
                                        height: 140,
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                "https://firebasestorage.googleapis.com/v0/b/graduation-project-5f333.firebasestorage.app/o/AppImages%2FKhartoum.jpg?alt=media&token=c85bebd6-4b14-498e-8dd9-9b16f4b350e1",
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withOpacity(
                                                        0.7,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 12,
                                                left: 12,
                                                right: 12,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Khartoum',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Explore Capital',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
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
                                  ),

                                  // --------------------
                                  // MERAWI
                                  // --------------------
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => {
                                        Provider.of<SearchProvider>(
                                          context,
                                          listen: false,
                                        ).updateCriteria(
                                          state: 'Northern',
                                          checkIn: null,
                                          checkOut: null,
                                          adults: 1,
                                          children: 0,
                                        ),
                                        Navigator.pushNamed(
                                          context,
                                          '/search_results',
                                        ),
                                      },
                                      child: Container(
                                        height: 140,
                                        margin: EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Stack(
                                            children: [
                                              Image.network(
                                                "https://firebasestorage.googleapis.com/v0/b/graduation-project-5f333.firebasestorage.app/o/AppImages%2FMerawi.jpg?alt=media&token=1a2d26ff-d0dd-44e0-bc3f-75a3f181f1f0",
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withOpacity(
                                                        0.7,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 12,
                                                left: 12,
                                                right: 12,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Marawi',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Nile Beauty',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
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
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // --------------------
                              // PORT SUDAN / RED SEA
                              // --------------------
                              GestureDetector(
                                onTap: () => {
                                  Provider.of<SearchProvider>(
                                    context,
                                    listen: false,
                                  ).updateCriteria(
                                    state: 'Red Sea',
                                    checkIn: null,
                                    checkOut: null,
                                    adults: 1,
                                    children: 0,
                                  ),
                                  Navigator.pushNamed(
                                    context,
                                    '/search_results',
                                  ),
                                },
                                child: Container(
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          "https://firebasestorage.googleapis.com/v0/b/graduation-project-5f333.firebasestorage.app/o/AppImages%2Fred_sea.jpg?alt=media&token=d79e6898-9dd8-4c86-a83b-3546dde5e962",
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.7),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          right: 12,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Port Sudan',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Red Sea Coast',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
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
                            ],
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
                        SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: const Footer(),
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
    );
  }
}
