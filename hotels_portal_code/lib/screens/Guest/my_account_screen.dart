import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/services/guest_service.dart';
import 'package:hotel_booking_app/widgets/account_header.dart';
import 'package:hotel_booking_app/widgets/account_nav_bar.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:hotel_booking_app/widgets/guest_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final String _profileImagePath = '';
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  String _selectedTab = 'Profile';
  bool _isEditing = false;
  bool _isLoading = false;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthDateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final Guest? currentUser = authProvider.currentGuest;
    if (currentUser != null) {
      setState(() {
        _firstNameController.text = currentUser.fName;
        _lastNameController.text = currentUser.lName;
        _emailController.text = currentUser.email;
        _phoneController.text = currentUser.phone ?? '';
        _selectedBirthDate = currentUser.birthDate;
        _birthDateController.text = currentUser.birthDate != null
            ? DateFormat('yyyy-MM-dd').format(currentUser.birthDate!)
            : '';
      });
    }
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    switch (tab) {
      case 'Profile':
        break;
      case 'My Bookings':
        Navigator.pushNamed(context, '/my_bookings');
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

  void _changeProfilePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change Photo functionality not implemented yet'),
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final guestService = GuestService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final updates = {
      'FName': _firstNameController.text,
      'LName': _lastNameController.text,
      'phone': _phoneController.text,
      'birthDate': _selectedBirthDate != null
          ? Timestamp.fromDate(_selectedBirthDate!)
          : null,
    };

    try {
      await guestService.updateGuest(
        authProvider.currentGuest!.guestId,
        updates,
      );
      await authProvider.refreshGuestData();
      _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: 'Enter your ${label.toLowerCase()}',
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF004D40)),
        ),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey[200] : Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFFBF0),
      drawer: const GuestSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            const AccountHeader(title: 'My Account'),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Information',
                                    style: TextStyle(
                                      color: Color(0xFF004D40),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Update your account details here.',
                                    style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                    if (!_isEditing) {
                                      _loadUserData();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isEditing ? Icons.close : Icons.edit,
                                  size: 16,
                                ),
                                label: Text(_isEditing ? 'Cancel' : 'Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isEditing
                                      ? Colors.grey
                                      : const Color(0xFF004D40),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage:
                                          _profileImagePath.isNotEmpty
                                          ? AssetImage(_profileImagePath)
                                          : null,
                                      child: _profileImagePath.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: _isEditing
                                                ? _changeProfilePhoto
                                                : null,
                                            icon: const Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                            ),
                                            label: const Text('Change Photo'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF004D40,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Accepted formats: JPG, PNG',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'First Name',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  'First Name',
                                  _firstNameController,
                                  enabled: _isEditing,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Last Name',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  'Last Name',
                                  _lastNameController,
                                  enabled: _isEditing,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  'Email',
                                  _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: false,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  'Phone Number',
                                  _phoneController,
                                  keyboardType: TextInputType.phone,
                                  enabled: _isEditing,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Birth Date',
                                  style: TextStyle(
                                    color: Color(0xFF004D40),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _birthDateController,
                                  enabled: _isEditing,
                                  readOnly: true,
                                  onTap: _isEditing ? _selectBirthDate : null,
                                  decoration: InputDecoration(
                                    hintText: 'Select your birth date',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    border: const OutlineInputBorder(),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF004D40),
                                      ),
                                    ),
                                    filled: !_isEditing,
                                    fillColor: !_isEditing
                                        ? Colors.grey[200]
                                        : Colors.white,
                                    suffixIcon: _isEditing
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            onPressed: _selectBirthDate,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_isEditing)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _saveChanges,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF004D40,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          : const Text(
                                              'Save Changes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
}
