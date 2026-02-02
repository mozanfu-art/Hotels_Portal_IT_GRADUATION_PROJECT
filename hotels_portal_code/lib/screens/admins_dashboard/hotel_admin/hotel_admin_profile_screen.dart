import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/admin.dart' as admin_model;
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/services/admin_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:provider/provider.dart';

class HotelAdminProfileScreen extends StatefulWidget {
  const HotelAdminProfileScreen({super.key});

  @override
  State<HotelAdminProfileScreen> createState() =>
      _HotelAdminProfileScreenState();
}

class _HotelAdminProfileScreenState extends State<HotelAdminProfileScreen> {
  bool isSidebarOpen = false;
  bool isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // New state for notification settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _isLoadingSettings = true;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentAdmin != null) {
      final admin = authProvider.currentAdmin!;
      _fNameController.text = admin.fName;
      _lNameController.text = admin.lName;
      _emailController.text = admin.email;

      // Load notification settings from the admin object
      if (admin.settings != null) {
        _emailNotifications = admin.settings!.emailNotifications;
        _pushNotifications = admin.settings!.pushNotifications;
      }
      setState(() => _isLoadingSettings = false);
    } else {
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final admin = authProvider.currentAdmin;
    if (admin == null) return;

    final currentSettings =
        admin.settings ?? admin_model.AdminSettings(updatedAt: DateTime.now());

    final newSettings = admin_model.AdminSettings(
      emailNotifications: key == 'emailNotifications'
          ? value
          : currentSettings.emailNotifications,
      pushNotifications: key == 'pushNotifications'
          ? value
          : currentSettings.pushNotifications,
      updatedAt: DateTime.now(),
    );

    try {
      await _adminService.updateAdminSettings(
        admin.adminId,
        newSettings.toMap(),
      );
      await authProvider.refreshGuestData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _loadUserData();
    }
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isEditing) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool changesMade = false;

    // --- Update Profile Info ---
    if (_fNameController.text != authProvider.currentAdmin?.fName ||
        _lNameController.text != authProvider.currentAdmin?.lName) {
      final profileError = await authProvider.updateAdminProfile(
        fName: _fNameController.text,
        lName: _lNameController.text,
      );
      if (profileError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile update failed: $profileError')),
        );
      } else {
        changesMade = true;
      }
    }

    // --- Update Password ---
    if (_newPasswordController.text.isNotEmpty) {
      final passwordError = await authProvider.updateUserPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (passwordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password update failed: $passwordError')),
        );
      } else {
        changesMade = true;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    }

    setState(() => _isSaving = false);

    if (changesMade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => isEditing = false);
    }
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              HotelAdminSidebar(
                isMobile: isMobile,
                isOpen: isSidebarOpen,
                onToggle: () => setState(() => isSidebarOpen = !isSidebarOpen),
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
                    if (!isMobile)
                      const Header(
                        title: "Profile Settings",
                        showBackButton: true,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 24),
                              _buildPasswordCard(),
                              const SizedBox(height: 24),
                              _buildNotificationsCard(),
                              const SizedBox(height: 24),
                              _buildActions(),
                              const SizedBox(height: 24),
                              Footer(),
                            ],
                          ),
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

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF004d40),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = !isEditing),
                icon: FaIcon(
                  isEditing ? FontAwesomeIcons.times : FontAwesomeIcons.edit,
                  size: 16,
                ),
                label: Text(isEditing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fNameController,
            enabled: isEditing,
            decoration: InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'First name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lNameController,
            enabled: isEditing,
            decoration: InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Last name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: false, // Email is not editable
            decoration: InputDecoration(
              labelText: 'Email (Cannot be changed)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004d40),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentPasswordController,
            enabled: isEditing,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (isEditing &&
                  _newPasswordController.text.isNotEmpty &&
                  v!.isEmpty) {
                return 'Current password is required to change it';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            enabled: isEditing,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Leave blank to keep current password',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (isEditing && v!.isNotEmpty && v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: isEditing,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (isEditing &&
                  _newPasswordController.text.isNotEmpty &&
                  v != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF004d40),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingSettings)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildNotificationBox(
              title: 'Email Notifications',
              isEnabled: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
                _updateNotificationSetting('emailNotifications', value);
              },
              description: 'Receive updates about bookings and platform news.',
            ),
            const SizedBox(height: 16),
            _buildNotificationBox(
              title: 'Push Notifications',
              isEnabled: _pushNotifications,
              onChanged: (value) {
                setState(() => _pushNotifications = value);
                _updateNotificationSetting('pushNotifications', value);
              },
              description: 'Get real-time alerts on your mobile device.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationBox({
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required String description,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF004d40),
        ),
      ),
      subtitle: Text(description),
      value: isEnabled,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF004d40),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActions() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: isEditing && !_isSaving ? _handleSaveChanges : null,
        icon: _isSaving
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : FaIcon(FontAwesomeIcons.save, size: 16),
        label: const Text('Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEditing ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
