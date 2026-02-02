import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

class HotelInfoAmenitiesScreen extends StatefulWidget {
  final Hotel hotel;

  const HotelInfoAmenitiesScreen({super.key, required this.hotel});

  @override
  State<HotelInfoAmenitiesScreen> createState() =>
      _HotelInfoAmenitiesScreenState();
}

class _HotelInfoAmenitiesScreenState extends State<HotelInfoAmenitiesScreen> {
  bool isSidebarOpen = false;
  late bool _isApproved;
  bool _isUpdatingStatus = false;
  final HotelService _hotelService = HotelService();
  final ActivityService _activityService = ActivityService();

  @override
  void initState() {
    super.initState();
    _isApproved = widget.hotel.approved;
  }

  Future<void> _updateApprovalStatus(bool newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _hotelService.updateHotel(widget.hotel.hotelId, {
        'approved': newStatus,
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'Hotel Status Update',
          description:
              'Hotel "${widget.hotel.hotelName}" has been ${newStatus ? "approved" : "rejected"}.',
          entityId: widget.hotel.hotelId,
          entityType: 'Hotel',
          actorId: authProvider.currentAdmin!.adminId,
          actorName:
              '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}',
          timestamp: Timestamp.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _isApproved = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hotel status updated to ${newStatus ? "Approved" : "Not Approved"}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  IconData _getIconForAmenity(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'restaurant':
        return FontAwesomeIcons.utensils;
      case 'conference rooms':
        return FontAwesomeIcons.users;
      case 'pool':
      case 'swimming pool':
        return FontAwesomeIcons.swimmingPool;
      case 'spa':
        return FontAwesomeIcons.spa;
      case 'free wifi':
      case 'wifi':
        return FontAwesomeIcons.wifi;
      case 'gym':
      case 'fitness center':
        return FontAwesomeIcons.dumbbell;
      case 'parking':
        return FontAwesomeIcons.parking;
      case 'concierge':
        return FontAwesomeIcons.conciergeBell;
      default:
        return FontAwesomeIcons.star;
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
              MinistryAdminSidebar(
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
                    if (!isMobile)
                      MinistryAdminHeader(title: widget.hotel.hotelName),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hotel Information & Status',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildStatusCard(),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildContactInfoCard()),
                                const SizedBox(width: 24),
                                Expanded(child: _buildAddressDescriptionCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildHotelGalleryCard(),
                            const SizedBox(height: 24),
                            _buildFacilitiesCard(),
                            const SizedBox(height: 24),
                            if (widget.hotel.restaurants.isNotEmpty) ...[
                              _buildRestaurantsCard(),
                              const SizedBox(height: 24),
                            ],
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

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval Status & Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text(
                'Hotel Approved',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _isApproved
                    ? 'The hotel is visible to guests and can receive bookings.'
                    : 'The hotel is hidden and cannot receive bookings.',
              ),
              value: _isApproved,
              onChanged: _isUpdatingStatus ? null : _updateApprovalStatus,
              activeThumbColor: Colors.green,
            ),
            if (_isUpdatingStatus)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const Divider(height: 32),
            Row(
              children: [
                _buildDetailItem(
                  FontAwesomeIcons.star,
                  'Rating',
                  widget.hotel.starRate.toString(),
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  FontAwesomeIcons.users,
                  'Conference Rooms',
                  widget.hotel.conferenceRoomsCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RatingBarIndicator(
              rating: widget.hotel.starRate.toDouble(),
              itemBuilder: (context, index) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.phone, color: const Color(0xFF004d40)),
              title: const Text('Phone'),
              subtitle: Text(widget.hotel.hotelPhone ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: const Color(0xFF004d40)),
              title: const Text('Email'),
              subtitle: Text(widget.hotel.hotelEmail ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDescriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address & Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.hotel.hotelAddress,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              widget.hotel.hotelDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelGalleryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hotel Gallery',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            widget.hotel.images.isEmpty
                ? const Center(child: Text('No images available.'))
                : SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.hotel.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.hotel.images[index],
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Facilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.hotel.amenities.map((amenity) {
                return _FacilityItem(
                  icon: _getIconForAmenity(amenity),
                  label: amenity,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF004d40),
              ),
            ),
            const SizedBox(height: 16),
            ...widget.hotel.restaurants.map((restaurant) {
              return ListTile(
                leading: const Icon(FontAwesomeIcons.utensils),
                title: Text(restaurant['name'] ?? 'N/A'),
                subtitle: Text(restaurant['location'] ?? 'N/A'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }
}

class _FacilityItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FacilityItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF004d40).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(icon, color: const Color(0xFF004d40), size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
