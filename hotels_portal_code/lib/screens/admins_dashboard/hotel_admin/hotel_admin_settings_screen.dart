import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotel_booking_app/models/hotel.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';
import 'package:hotel_booking_app/providers/hotel_provider.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_header.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/widgets/hotel_admin_sidebar.dart';
import 'package:hotel_booking_app/screens/admins_dashboard/welcome_screen.dart';
import 'package:hotel_booking_app/services/hotel_service.dart';
import 'package:hotel_booking_app/widgets/footer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HotelAdminSettingsScreen extends StatefulWidget {
  const HotelAdminSettingsScreen({super.key});

  @override
  State<HotelAdminSettingsScreen> createState() =>
      _HotelAdminSettingsScreenState();
}

class _HotelAdminSettingsScreenState extends State<HotelAdminSettingsScreen> {
  bool isSidebarOpen = false;
  bool isEditing = false;
  bool isSaving = false;
  bool _isDataLoaded = false;

  final HotelService _hotelService = HotelService();

  // Controllers
  final hotelNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  double hotelRating = 0.0;

  List<String> _currentImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final List<String> _imagesToDelete = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final authProvider = Provider.of<AuthProvider>(context);
      if (authProvider.hotelId != null) {
        _loadHotelData(authProvider.hotelId!);
        _isDataLoaded = true;
      }
    }
  }

  Future<void> _loadHotelData(String hotelId) async {
    final Hotel? hotelInfo = Provider.of<HotelProvider>(
      context,
      listen: false,
    ).hotel;

    if (hotelInfo != null) {
      setState(() {
        hotelNameController.text = hotelInfo.hotelName;
        phoneController.text = hotelInfo.hotelPhone ?? '';
        emailController.text = hotelInfo.hotelEmail ?? '';
        addressController.text = hotelInfo.hotelAddress;
        descriptionController.text = hotelInfo.hotelDescription;
        hotelRating = hotelInfo.starRate.toDouble();
        _currentImageUrls = List<String>.from(hotelInfo.images);
      });
    }
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

  Future<void> _saveHotelInfo() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hotelId = authProvider.hotelId;
    if (hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find hotel to update.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isSaving = false);
      return;
    }

    try {
      for (var url in _imagesToDelete) {
        await _hotelService.deleteHotelImage(url);
      }

      List<String> newImageUrls = [];
      for (var file in _newImageFiles) {
        final bytes = await file.readAsBytes();
        final url = await _hotelService.uploadHotelImage(
          hotelId,
          bytes,
          file.name,
        );
        newImageUrls.add(url);
      }

      final finalImageUrls = List<String>.from(_currentImageUrls)
        ..addAll(newImageUrls);

      final updatedData = {
        'hotelName': hotelNameController.text,
        'hotelPhone': phoneController.text,
        'hotelEmail': emailController.text,
        'hotelAddress': addressController.text,
        'hotelDescription': descriptionController.text,
        'starRate': hotelRating.toInt(),
        'images': finalImageUrls,
      };

      await _hotelService.updateHotel(hotelId, updatedData);
      await Provider.of<HotelProvider>(
        context,
        listen: false,
      ).getHotel(hotelId);

      setState(() {
        isEditing = false;
        _newImageFiles.clear();
        _imagesToDelete.clear();
      });

      await _loadHotelData(hotelId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotel information updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update hotel information: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    hotelNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // 🔹 Helper Widgets

  Widget _buildHotelInfoCard() {
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
              const Text(
                'Hotel Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004d40),
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
          _buildTextField(hotelNameController, 'Hotel Name'),
          const SizedBox(height: 16),
          _buildTextField(phoneController, 'Phone Number'),
          const SizedBox(height: 16),
          _buildTextField(emailController, 'Email Address'),
          const SizedBox(height: 16),
          _buildTextField(addressController, 'Address', maxLines: 3),
          const SizedBox(height: 16),
          _buildTextField(
            descriptionController,
            'Hotel Description',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildRatingBar(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF004d40),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: isEditing,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotel Rating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF004d40),
          ),
        ),
        const SizedBox(height: 4),
        if (isEditing)
          RatingBar.builder(
            initialRating: hotelRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 30,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => setState(() => hotelRating = rating),
          )
        else
          Row(
            children: [
              RatingBarIndicator(
                rating: hotelRating,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 30,
              ),
              const SizedBox(width: 8),
              Text(
                '${hotelRating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF004d40),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHotelPhotosCard() {
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
              const Text(
                'Hotel Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004d40),
                ),
              ),
              if (isEditing)
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Add Images'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildImageSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._currentImageUrls.map(
          (url) => _buildImageThumbnail(imageSource: url, isFile: false),
        ),
        ..._newImageFiles.map(
          (file) => _buildImageThumbnail(imageSource: file, isFile: true),
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

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        if (isEditing)
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
    );
  }

  Widget _buildSaveChangesAction() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : _saveHotelInfo,
        icon: isSaving
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const FaIcon(FontAwesomeIcons.save, size: 16),
        label: const Text('Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
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
                              icon: const FaIcon(
                                FontAwesomeIcons.bars,
                                color: Color(0xFF004d40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isMobile)
                      const HotelAdminHeader(
                        title: '',
                        mainTitle: 'Hotel Settings',
                        showBackButton: true,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildHotelInfoCard(),
                            const SizedBox(height: 24),
                            _buildHotelPhotosCard(),
                            const SizedBox(height: 24),
                            if (isEditing) _buildSaveChangesAction(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Legal'),
                            const SizedBox(height: 16),
                            _buildLegalBox(
                              icon: Icons.lock,
                              title: 'Hotel Policy',
                              onTap: _showHotelPolicy,
                            ),
                            const SizedBox(height: 16),
                            _buildLegalBox(
                              icon: Icons.lock,
                              title: 'Privacy Policy',
                              onTap: _showPrivacyPolicy,
                            ),
                            const SizedBox(height: 16),
                            _buildLegalBox(
                              icon: Icons.description,
                              title: 'Terms of Service',
                              onTap: _showTermsOfService,
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Account Management'),
                            const SizedBox(height: 16),
                            _buildLegalBox(
                              icon: Icons.delete_forever,
                              title: 'Delete Account',
                              onTap: _showDeleteAccountDialog,
                            ),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF004d40),
        ),
      ),
    );
  }

  Widget _buildLegalBox({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _showHotelPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hotel Policy'),
        content: const Text(
          'This is a placeholder for the Hotel Policy content. In a real app, load from assets or web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'This is a placeholder for the Privacy Policy content. In a real app, load from assets or web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text(
          'This is a placeholder for the Terms of Service content. In a real app, load from assets or web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Enter your password to confirm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => isDeleting = true);
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final error = await authProvider.deleteAccount(
                        passwordController.text,
                      );
                      if (mounted) {
                        if (error == null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deleted successfully.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomeScreen(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setState(() => isDeleting = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
