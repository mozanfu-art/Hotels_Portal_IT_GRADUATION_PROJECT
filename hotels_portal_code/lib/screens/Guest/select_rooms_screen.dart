import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/services/booking_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

class SelectRoomsScreen extends StatefulWidget {
  final Hotel hotel;
  final DateTime initialCheckInDate;
  final DateTime initialCheckOutDate;
  final int initialNumberOfGuests;

  const SelectRoomsScreen({
    super.key,
    required this.hotel,
    required this.initialCheckInDate,
    required this.initialCheckOutDate,
    required this.initialNumberOfGuests,
  });

  @override
  State<SelectRoomsScreen> createState() => _SelectRoomsScreenState();
}

class _SelectRoomsScreenState extends State<SelectRoomsScreen> {
  late DateTime checkInDate;
  late DateTime checkOutDate;
  late int totalAdults;
  late int totalChildren;
  bool _isLoading = false;

  List<Room> _availableRooms = [];
  final BookingService _bookingService = BookingService();

  /// A getter to compute the number of nights directly from the dates.
  /// This ensures the value is always accurate.
  int get numberOfNights {
    // Ensure checkout is after check-in, return 0 if dates are invalid
    if (checkOutDate.isAfter(checkInDate)) {
      return checkOutDate.difference(checkInDate).inDays;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    checkInDate = widget.initialCheckInDate;
    checkOutDate = widget.initialCheckOutDate;

    totalAdults = widget.initialNumberOfGuests;
    totalChildren = widget.initialNumberOfGuests;
  }

  /// Updates the dates and clears the available rooms list to prompt a new search.
  void _updateDates() {
    setState(() {
      // Ensure check-out date is always at least one day after the check-in date
      if (!checkOutDate.isAfter(checkInDate)) {
        checkOutDate = checkInDate.add(const Duration(days: 1));
      }
      _availableRooms = []; // Clear results when dates change
    });
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != checkInDate) {
      setState(() {
        checkInDate = picked;
        _updateDates();
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: checkOutDate,
      firstDate: checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != checkOutDate) {
      setState(() {
        checkOutDate = picked;
        _updateDates();
      });
    }
  }

  void _showGuestsDialog() {
    int dialogAdults = totalAdults;
    int dialogChildren = totalChildren;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Select Number of Guests',
                style: TextStyle(color: Color(0xFF004D40)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCounterRow(
                    'Adults',
                    dialogAdults,
                    (val) {
                      setDialogState(() => dialogAdults = val);
                    },
                    1,
                    10,
                  ),
                  const SizedBox(height: 16),
                  _buildCounterRow(
                    'Children',
                    dialogChildren,
                    (val) {
                      setDialogState(() => dialogChildren = val);
                    },
                    0,
                    10,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      totalAdults = dialogAdults;
                      totalChildren = dialogChildren;
                      _availableRooms = []; // Clear results when guests change
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Checks for available rooms using the efficient [BookingService].
  Future<void> _checkAvailability() async {
    setState(() {
      _isLoading = true;
      _availableRooms = [];
    });

    try {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
      await hotelProvider.loadRooms(widget.hotel.hotelId);
      final allHotelRooms = hotelProvider.rooms;

      final availableRoomCounts = await _bookingService.getAvailableRoomCounts(
        widget.hotel.hotelId,
        checkInDate,
        checkOutDate,
      );

      List<Room> availableRoomsResult = [];
      final addedRoomTypes = <String>{};

      for (final room in allHotelRooms) {
        if (addedRoomTypes.contains(room.roomType)) {
          continue;
        }

        final availableCount = availableRoomCounts[room.roomType] ?? 0;
        final hasCapacity =
            room.maxAdults >= totalAdults && room.maxChildren >= totalChildren;

        if (availableCount > 0 && hasCapacity) {
          availableRoomsResult.add(room);
          addedRoomTypes.add(room.roomType);
        }
      }

      availableRoomsResult.sort(
        (a, b) => a.pricePerNight.compareTo(b.pricePerNight),
      );

      setState(() {
        _availableRooms = availableRoomsResult;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Room'),
            const SizedBox(height: 4),
            Text(
              widget.hotel.hotelName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFFFFBF0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEditableField(
                              'Check-in',
                              _formatDate(checkInDate),
                              Icons.calendar_today,
                              _selectCheckInDate,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryField(
                              'Nights',
                              numberOfNights.toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEditableField(
                              'Check-out',
                              _formatDate(checkOutDate),
                              Icons.calendar_today,
                              _selectCheckOutDate,
                            ),
                            const SizedBox(height: 8),
                            _buildEditableField(
                              'Guests',
                              (totalAdults + totalChildren).toString(),
                              Icons.people,
                              _showGuestsDialog,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Check Available Rooms'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available Rooms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableRooms.isEmpty
                  ? const Center(
                      child: Text(
                        'No available rooms for the selected criteria. Please adjust dates or guest count.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _availableRooms.length,
                      itemBuilder: (context, index) {
                        final room = _availableRooms[index];
                        final totalPrice = room.pricePerNight * numberOfNights;
                        return _buildRoomCard(room, totalPrice);
                      },
                    ),
            ),
            const SizedBox(height: 24),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room, double totalPrice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                room.images.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Icon(Icons.room, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            room.roomType,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Maximum Guests: ${room.maxAdults} Adults, ${room.maxChildren} Children',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: room.amenities
                .map(
                  (amenity) => Chip(
                    label: Text(amenity),
                    backgroundColor: Colors.grey[200],
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Total for $numberOfNights nights: \$${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF004D40),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/confirm_booking',
                arguments: {
                  'hotel': widget.hotel.toJson(),
                  'selectedRoom': room.toMap(), // Pass room data
                  'checkInDate': checkInDate,
                  'checkOutDate': checkOutDate,
                  'adults': totalAdults,
                  'children': totalChildren,
                },
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Select Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF004D40)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterRow(
    String label,
    int count,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF004D40),
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: count > min ? () => onChanged(count - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Text(
              '$count',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            IconButton(
              onPressed: count < max ? () => onChanged(count + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
