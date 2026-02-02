import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/models/app_user.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/services/admin_service.dart';
import 'package:hotel_booking_app/services/guest_service.dart';

class UserProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  final GuestService _guestService = GuestService();
  final ActivityService _activityService = ActivityService();

  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _error;

  // New state for hotel guests
  List<Map<String, dynamic>> _hotelGuests = [];
  List<Map<String, dynamic>> get hotelGuests => _hotelGuests;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final admins = await _adminService.getAllAdmins();
      final guests = await _guestService.getAllGuests();

      final List<AppUser> combinedUsers = [];
      combinedUsers.addAll(admins.map((admin) => AppUser.fromAdmin(admin)));
      combinedUsers.addAll(guests.map((guest) => AppUser.fromGuest(guest)));

      // Sort by name
      combinedUsers.sort((a, b) => a.name.compareTo(b.name));

      _users = combinedUsers;
    } catch (e, s) {
      print(s);
      _error = e.toString();
      print("Error fetching users: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to fetch guest history for a specific hotel
  Future<void> fetchGuestsForHotel(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hotelGuests = await _guestService.getGuestsForHotel(hotelId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(
    AppUser user,
    String adminId,
    String adminName,
  ) async {
    try {
      if (user.role.toLowerCase() == 'guest') {
        await _guestService.updateGuest(user.id, {'active': !user.isActive});
      } else {
        await _adminService.updateAdmin(user.id, {'active': !user.isActive});
      }
      // Refresh the user list to show the updated status
      await fetchAllUsers();

      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'User Status Update',
          description:
              'The status of user "${user.name}" has been changed to ${!user.isActive ? "Active" : "Inactive"}.',
          entityId: user.id,
          entityType: 'User',
          actorId: adminId,
          actorName: adminName,
          timestamp: Timestamp.now(),
        ),
      );
    } catch (e) {
      _error = 'Failed to update user status: ${e.toString()}';
      notifyListeners();
    }
  }
}
