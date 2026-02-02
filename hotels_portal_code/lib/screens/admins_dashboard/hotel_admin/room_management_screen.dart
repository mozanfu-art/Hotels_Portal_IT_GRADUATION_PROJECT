// lib/screens/Admins dashboard/hotel_admin/room_management_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/room.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  bool isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.hotelId != null) {
        Provider.of<HotelProvider>(
          context,
          listen: false,
        ).loadRooms(authProvider.hotelId!);
      }
    });
  }

  void _showAddRoomDialog(String hotelId) {
    showDialog(
      context: context,
      builder: (context) => _AddRoomDialog(hotelId: hotelId),
    );
  }

  void _showEditRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddRoomDialog(hotelId: room.hotelId, roomToEdit: room),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 768;
          return Row(
            children: [
              HotelAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (isMobile)
                      // Mobile Header
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(
                                () => isSidebarOpen = !isSidebarOpen,
                              ),
                              icon: FaIcon(
                                FontAwesomeIcons.bars,
                                color: const Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isMobile) const Header(title: "Room Management"),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Header Section (Title & Search)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room Management',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF004d40),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      // Search Field
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Search rooms...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: Colors.grey,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (authProvider.hotelId != null) {
                                            _showAddRoomDialog(
                                              authProvider.hotelId!,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Room'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF004d40,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          // Room Grid
                          Consumer<HotelProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoading) {
                                // Show placeholder grid while loading
                                return SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  sliver: SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isMobile ? 1 : 3,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.5,
                                        ),
                                    itemCount: 6,
                                    itemBuilder: (context, index) =>
                                        const _RoomCardPlaceholder(),
                                  ),
                                );
                              }
                              if (provider.error != null) {
                                return SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(
                                      'An error occurred: ${provider.error}',
                                    ),
                                  ),
                                );
                              }
                              if (provider.rooms.isEmpty) {
                                return const SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(
                                      'No rooms found. Add a room to get started.',
                                    ),
                                  ),
                                );
                              }
                              return SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                sliver: SliverGrid.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isMobile ? 1 : 3,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 1.5,
                                      ),
                                  itemCount: provider.rooms.length,
                                  itemBuilder: (context, index) {
                                    final room = provider.rooms[index];
                                    return _RoomCard(
                                      room: room,
                                      onEdit: () => _showEditRoomDialog(room),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          // Footer (Sticky at bottom)
                          SliverFillRemaining(
                            hasScrollBody: false,

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                  ),
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
            ],
          );
        },
      ),
    );
  }
}

// ... (Widget _RoomCardPlaceholder remains the same) ...
class _RoomCardPlaceholder extends StatefulWidget {
  const _RoomCardPlaceholder();

  @override
  State<_RoomCardPlaceholder> createState() => _RoomCardPlaceholderState();
}

class _RoomCardPlaceholderState extends State<_RoomCardPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlaceholderBox(height: 20, width: 120),
                  _buildPlaceholderBox(height: 24, width: 80),
                ],
              ),
              _buildPlaceholderBox(height: 16, width: 100),
              _buildPlaceholderBox(height: 18, width: 80),
              Row(
                children: [
                  Expanded(child: _buildPlaceholderBox(height: 36)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPlaceholderBox(height: 36)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onEdit;
  const _RoomCard({required this.room, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = room.available ? Colors.green : Colors.orange;
    final String statusText = room.available ? 'Available' : 'Unavailable';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  room.roomType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF004d40),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Max Guests: ${room.maxAdults} Adults, ${room.maxChildren} Children',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              '\$${room.pricePerNight.toStringAsFixed(2)}/night',
              style: TextStyle(
                color: const Color(0xFF004d40),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004d40),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/hotel-room-details',
                        arguments: room,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004d40),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ... (_RoomCard widget remains the same) ...

class _AddRoomDialog extends StatefulWidget {
  final String hotelId;
  final Room? roomToEdit;
  const _AddRoomDialog({required this.hotelId, this.roomToEdit});

  @override
  _AddRoomDialogState createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<_AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers and State
  final List<String> _roomTypes = [
    'King',
    'Queen',
    'Single',
    'Twins',
    'Suite',
    'Apartment',
    'Deluxe',
    'Business',
  ];
  String? _selectedRoomType;
  final _descriptionController = TextEditingController();
  int _maxAdults = 1;
  int _maxChildren = 0;
  final _priceController = TextEditingController();
  final _amenitiesController = TextEditingController();
  bool _isAvailable = true;

  // Image management state
  List<String> _currentImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final List<String> _imagesToDelete = [];

  @override
  void initState() {
    super.initState();
    if (widget.roomToEdit != null) {
      _selectedRoomType = widget.roomToEdit!.roomType;
      _descriptionController.text = widget.roomToEdit!.roomDescription;
      _maxAdults = widget.roomToEdit!.maxAdults;
      _maxChildren = widget.roomToEdit!.maxChildren;
      _priceController.text = widget.roomToEdit!.pricePerNight.toString();
      _amenitiesController.text = widget.roomToEdit!.amenities.join(', ');
      _isAvailable = widget.roomToEdit!.available;
      _currentImageUrls = List<String>.from(widget.roomToEdit!.images);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(images);
      });
    }
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final hotelService = HotelService();
    final isEditing = widget.roomToEdit != null;
    final roomId = isEditing
        ? widget.roomToEdit!.roomId
        : FirebaseFirestore.instance.collection('temp').doc().id;

    try {
      // 1. Delete marked images from storage
      for (final url in _imagesToDelete) {
        await hotelService.deleteHotelImage(url);
      }

      // 2. Upload new images to storage
      List<String> newImageUrls = [];
      for (final file in _newImageFiles) {
        final bytes = await file.readAsBytes();
        final url = await hotelService.uploadRoomImage(
          widget.hotelId,
          roomId,
          bytes,
          file.name,
        );
        newImageUrls.add(url);
      }

      // 3. Combine image URLs for the final list
      final finalImageUrls = List<String>.from(_currentImageUrls)
        ..addAll(newImageUrls);

      // 4. Create or update the Room object
      final roomData = Room(
        roomId: roomId,
        hotelId: widget.hotelId,
        roomType: _selectedRoomType!,
        roomDescription: _descriptionController.text,
        maxChildren: _maxChildren,
        maxAdults: _maxAdults,
        pricePerNight: double.parse(_priceController.text),
        amenities: _amenitiesController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        images: finalImageUrls, // Use the final combined list
        available: _isAvailable,
        createdAt: isEditing ? widget.roomToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = Provider.of<HotelProvider>(context, listen: false);
      if (isEditing) {
        await provider.updateRoom(roomData);
      } else {
        await provider.addRoom(roomData);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Room ${isEditing ? 'updated' : 'added'} successfully!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save room: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.roomToEdit == null ? 'Add New Room' : 'Edit Room'),
      content: SizedBox(
        width: 600, // Make the dialog wider for images
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  initialValue: _selectedRoomType,
                  hint: const Text('Select Room Type'),
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: _roomTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedRoomType = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a room type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) =>
                      v!.isEmpty ? 'This field is required' : null,
                ),
                const SizedBox(height: 16),
                _CounterField(
                  label: 'Max Adults',
                  value: _maxAdults,
                  min: 1, // At least one adult
                  onChanged: (val) {
                    setState(() {
                      _maxAdults = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _CounterField(
                  label: 'Max Children',
                  value: _maxChildren,
                  onChanged: (val) {
                    setState(() {
                      _maxChildren = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Night',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (v) => v!.isEmpty || double.tryParse(v) == null
                      ? 'Enter a valid price'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma-separated)',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'This field is required' : null,
                ),
                SwitchListTile(
                  title: const Text('Is Available'),
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
                const SizedBox(height: 16),
                _buildPhotosSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoom,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Room Photos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (_currentImageUrls.isEmpty && _newImageFiles.isEmpty)
              ? const Center(child: Text('No images added.'))
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: [
                    ..._currentImageUrls.map(
                      (url) =>
                          _buildImageThumbnail(imageSource: url, isFile: false),
                    ),
                    ..._newImageFiles.map(
                      (file) =>
                          _buildImageThumbnail(imageSource: file, isFile: true),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    required dynamic imageSource,
    required bool isFile,
  }) {
    ImageProvider imageProvider;
    if (isFile) {
      final xFile = imageSource as XFile;
      imageProvider = kIsWeb
          ? NetworkImage(xFile.path)
          : FileImage(File(xFile.path)) as ImageProvider;
    } else {
      imageProvider = NetworkImage(imageSource as String);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isFile) {
                    _newImageFiles.remove(imageSource);
                  } else {
                    _imagesToDelete.add(imageSource);
                    _currentImageUrls.remove(imageSource);
                  }
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _CounterField({
    required this.label,
    required this.value,
    required this.onChanged,
    int min = 0,
    int max = 10,
  }) : min = min,
       max = max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
