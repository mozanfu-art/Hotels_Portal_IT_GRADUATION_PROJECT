import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/ministry_admin_sidebar.dart';
import 'package:hotel_booking_app/services/admin_service.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:hotel_booking_app/utils/constants.dart';
import 'package:provider/provider.dart';
import 'hotel_info_amenities_screen.dart' as ministry_hotel_info;
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/models/admin.dart' as model;
import 'package:hotel_booking_app/models/hotel.dart' as model;

import 'package:hotel_booking_app/providers/auth_provider.dart'
    as auth_provider;

class HotelRegistryScreen extends StatefulWidget {
  const HotelRegistryScreen({super.key});

  @override
  State<HotelRegistryScreen> createState() => _HotelRegistryScreenState();
}

class _HotelRegistryScreenState extends State<HotelRegistryScreen> {
  bool isSidebarOpen = false;
  final AdminService _adminService = AdminService();

  void _showAddHotelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const _AddHotelDialog();
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pending':
        bgColor = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfffbf0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHotelDialog,
        backgroundColor: const Color(0xFF004d40),
        icon: const Icon(Icons.add),
        label: const Text('Register Hotel'),
      ),
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
                              icon: const FaIcon(
                                FontAwesomeIcons.bars,
                                color: Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isMobile)
                      const MinistryAdminHeader(title: 'Hotel Registry'),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Registered Hotels',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF004d40),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: _adminService.getAllHotels(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return SliverToBoxAdapter(
                                  child: Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  ),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const SliverFillRemaining(
                                  child: Center(
                                    child: Text(
                                      'No hotels found. Add one to get started.',
                                    ),
                                  ),
                                );
                              }

                              final hotels = snapshot.data!.docs;

                              return SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final hotelData =
                                        hotels[index].data()
                                            as Map<String, dynamic>;

                                    final name =
                                        hotelData['hotelName'] ??
                                        'Unnamed Hotel';
                                    final location =
                                        '${hotelData['hotelCity'] ?? 'N/A'}, ${hotelData['hotelState'] ?? 'N/A'}';
                                    final rating =
                                        (hotelData['starRate'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    final approved =
                                        hotelData['approved'] as bool? ?? false;
                                    final status = approved
                                        ? 'Active'
                                        : 'Pending';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          final hotel = model.Hotel.fromMap(
                                            hotelData,
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ministry_hotel_info.HotelInfoAmenitiesScreen(
                                                    hotel: hotel,
                                                  ),
                                            ),
                                          );
                                        },
                                        leading: const FaIcon(
                                          FontAwesomeIcons.hotel,
                                          color: Color(0xFF004d40),
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(location),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(rating.toStringAsFixed(1)),
                                            const SizedBox(width: 16),
                                            _buildStatusChip(status),
                                          ],
                                        ),
                                      ),
                                    );
                                  }, childCount: hotels.length),
                                ),
                              );
                            },
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    20,
                                    20,
                                    10,
                                  ),
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
            ],
          );
        },
      ),
    );
  }
}

class _AddHotelDialog extends StatefulWidget {
  const _AddHotelDialog();

  @override
  _AddHotelDialogState createState() => _AddHotelDialogState();
}

class _AddHotelDialogState extends State<_AddHotelDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Hotel Controllers
  final _hotelNameController = TextEditingController();
  String? _selectedState;
  final _hotelCityController = TextEditingController();
  final _hotelAddressController = TextEditingController();
  final _hotelEmailController = TextEditingController();
  final _hotelPhoneController = TextEditingController();
  final _hotelDescriptionController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final int _starRate = 3;

  // Admin Controllers
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _hotelNameController.dispose();
    _hotelCityController.dispose();
    _hotelAddressController.dispose();
    _hotelEmailController.dispose();
    _hotelPhoneController.dispose();
    _hotelDescriptionController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _registerHotelAndAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCredential? userCredential;

    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'secondaryApp', // Provide a unique name for the secondary app
      options:
          Firebase.app().options, // Use the same options as your default app
    );
    final tempAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      // 1. Create Firebase Auth user for the admin
      userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: _adminEmailController.text.trim(),
        password: _adminPasswordController.text,
      );
      final adminId = userCredential.user!.uid;

      // 2. Create the Hotel object
      final hotelId = FirebaseFirestore.instance.collection('hotels').doc().id;
      final newHotel = model.Hotel(
        hotelId: hotelId,
        hotelName: _hotelNameController.text,
        hotelState: _selectedState!,
        hotelCity: _hotelCityController.text,
        hotelAddress: _hotelAddressController.text,
        hotelEmail: _hotelEmailController.text,
        hotelPhone: _hotelPhoneController.text,
        hotelDescription: _hotelDescriptionController.text,
        licenseNumber: _licenseNumberController.text,
        starRate: _starRate,
        approved: true, // Approved by default as ministry is adding it
        adminId: adminId, // Associate admin
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Save Hotel to Firestore
      final hotelService = HotelService();
      final authProvider = Provider.of<auth_provider.AuthProvider>(
        context,
        listen: false,
      );
      final currentAdminId = authProvider.currentAdmin!.adminId;
      final currentAdminName =
          '${authProvider.currentAdmin!.fName} ${authProvider.currentAdmin!.lName}';
      await hotelService.createHotel(
        newHotel,
        currentAdminId,
        currentAdminName,
      );

      // 4. Create the Admin object
      final newAdmin = model.Admin(
        adminId: adminId,
        fName: _adminFirstNameController.text,
        lName: _adminLastNameController.text,
        email: _adminEmailController.text,
        hotelAddress: _hotelAddressController.text,
        hotelCity: _hotelCityController.text,
        hotelState: _selectedState!,
        hotelName: _hotelNameController.text,
        hotelId: hotelId, // Associate hotel
        role: 'hotel admin',
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 5. Save Admin to Firestore
      final adminService = AdminService();
      await adminService.createAdmin(newAdmin);

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotel and Admin registered successfully!'),
        ),
      );
    } catch (e) {
      // Rollback: If user was created but something else failed, delete the user
      if (userCredential != null) {
        await userCredential.user?.delete();
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register New Hotel'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5, // Make dialog wider
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hotel Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _hotelNameController,
                  decoration: const InputDecoration(labelText: 'Hotel Name'),
                  validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'License Number',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter a license number' : null,
                ),
                TextFormField(
                  controller: _hotelEmailController,
                  decoration: const InputDecoration(labelText: 'Hotel Email'),
                  validator: (v) => v!.isEmpty ? 'Please enter an email' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  dropdownColor: Colors.white,
                  hint: const Text('Select a State'),
                  items: sudaneseStates
                      .map(
                        (state) =>
                            DropdownMenuItem(value: state, child: Text(state)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a state' : null,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                TextFormField(
                  controller: _hotelCityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => v!.isEmpty ? 'Please enter a city' : null,
                ),
                TextFormField(
                  controller: _hotelAddressController,
                  decoration: const InputDecoration(labelText: 'Hotel Address'),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter an address' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Admin Account Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _adminFirstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin First Name',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter a first name' : null,
                ),
                TextFormField(
                  controller: _adminLastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Last Name',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter a last name' : null,
                ),
                TextFormField(
                  controller: _adminEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Login Email',
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter an email' : null,
                ),
                TextFormField(
                  controller: _adminPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Initial Password',
                  ),
                  obscureText: true,
                  validator: (v) => v!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
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
          onPressed: _isLoading ? null : _registerHotelAndAdmin,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Register'),
        ),
      ],
    );
  }
}
