import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/activity.dart';
import 'package:hotel_booking_app/models/admin.dart';
import 'package:hotel_booking_app/models/guest.dart';
import 'package:hotel_booking_app/services/activity_service.dart';
import 'package:hotel_booking_app/services/admin_service.dart';
import 'package:hotel_booking_app/services/guest_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GuestService _guestService = GuestService();
  final AdminService _adminService = AdminService();
  final ActivityService _activityService = ActivityService();

  User? _user;
  Guest? _currentGuest;
  Admin? _currentAdmin;
  String? _role; // 'guest' or 'admin'
  String? _hotelId; // for hotel admin
  String? _lastFCMToken; // to avoid unnecessary updates

  User? get user => _user;
  Guest? get currentGuest => _currentGuest;
  Admin? get currentAdmin => _currentAdmin;
  String? get role => _role;
  String? get hotelId => _hotelId;
  String? get userId => _user?.uid;
  bool get isLoggedIn => _user != null;
  bool get isMinistryAdmin => _hotelId == null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
      await _updateFCMToken();
    } else {
      _currentGuest = null;
      _currentAdmin = null;
      _role = null;
      _hotelId = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    // Check if the user is an admin
    try {
      Admin? admin = await _adminService.getAdmin(uid);
      if (admin != null) {
        _currentAdmin = admin;
        _role = 'admin';
        _hotelId = _currentAdmin!.hotelId;
        _currentGuest = null; // Ensure guest data is cleared
        notifyListeners();
        return;
      }
    } catch (e) {
      // Permission denied is expected for non-admin users, continue to guest check
      if (!e.toString().contains('permission-denied')) {
        print('Error checking admin data: $e');
        rethrow;
      }
    }

    // Check if the user is a guest
    try {
      Guest? guest = await _guestService.getGuest(uid);
      if (guest != null) {
        _currentGuest = guest;
        _role = 'guest';
        _hotelId = null;
        _currentAdmin = null; // Ensure admin data is cleared
        notifyListeners();
        return;
      }
    } catch (e) {
      print('Error getting guest data: $e');
      rethrow;
    }

    // If user is not found in either collection (edge case), sign them out
    print(
      "User $uid not found in 'admins' or 'guests' collection. Signing out.",
    );
    await signOut();
  }

  Future<void> refreshGuestData() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fName,
    required String lName,
    String? phone,
    DateTime? birthDate,
  }) async {
    try {
      // Check if email already exists in guests
      bool emailExists = await _guestService.checkEmailExists(email);
      if (emailExists) {
        return 'Email already exists';
      }

      // Create Firebase Auth user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create guest document in Firestore
      String guestId = userCredential.user!.uid;
      Guest newGuest = Guest(
        guestId: guestId,
        fName: fName,
        lName: lName,
        email: email,
        birthDate: birthDate,
        phone: phone,
        active: true,
        role: 'guest',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _guestService.createGuest(newGuest);

      await _activityService.createActivity(
        Activity(
          id: '',
          type: 'New User Registration',
          description: 'A new guest "$fName $lName" has registered.',
          entityId: guestId,
          entityType: 'Guest',
          actorId: guestId,
          actorName: '$fName $lName',
          timestamp: Timestamp.now(),
        ),
      );

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred';
    }
  }

  Future<void> toggleFavorite(String hotelId) async {
    if (_currentGuest == null) return;

    final guestId = _currentGuest!.guestId;
    final currentFavorites = List<String>.from(_currentGuest!.favoriteHotelIds);

    // Optimistically update the UI
    if (currentFavorites.contains(hotelId)) {
      currentFavorites.remove(hotelId);
    } else {
      currentFavorites.add(hotelId);
    }

    _currentGuest = _currentGuest!.copyWith(favoriteHotelIds: currentFavorites);
    notifyListeners();

    // Call the service to update Firestore
    try {
      await _guestService.toggleFavoriteHotel(guestId, hotelId);
    } catch (e) {
      // If the update fails, revert the change and notify listeners
      final revertedFavorites = List<String>.from(
        _currentGuest!.favoriteHotelIds,
      );
      if (revertedFavorites.contains(hotelId)) {
        revertedFavorites.remove(hotelId);
      } else {
        revertedFavorites.add(hotelId);
      }
      _currentGuest = _currentGuest!.copyWith(
        favoriteHotelIds: revertedFavorites,
      );
      notifyListeners();
      // Optionally, show an error message
      print("Error toggling favorite: $e");
    }
  }

  Future<String?> signIn(
    String email,
    String password, {
    bool isAdminLogin = false,
  }) async {
    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return 'Login failed. User not found.';
      }

      // 2. Check user's role and status in Firestore
      if (isAdminLogin) {
        // Admin login attempt
        DocumentSnapshot adminDoc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get();
        if (!adminDoc.exists) {
          await _auth.signOut();
          return 'This account does not have admin privileges.';
        }
        final adminData = adminDoc.data() as Map<String, dynamic>;
        if (adminData['active'] == false) {
          await _auth.signOut();
          return 'Your admin account has been disabled.';
        }
      } else {
        // Guest login attempt
        try {
          DocumentSnapshot adminDoc = await _firestore
              .collection('admins')
              .doc(user.uid)
              .get();
          if (adminDoc.exists) {
            await _auth.signOut();
            return 'Admin accounts cannot log in to the guest app.';
          }
        } catch (e) {
          // Permission denied is expected for non-admin users, continue
          if (!e.toString().contains('permission-denied')) {
            await _auth.signOut();
            return 'An error occurred during login validation.';
          }
        }
        DocumentSnapshot guestDoc = await _firestore
            .collection('guests')
            .doc(user.uid)
            .get();
        if (!guestDoc.exists) {
          await _auth.signOut();
          return 'This account is not registered as a guest.';
        }
        final guestData = guestDoc.data() as Map<String, dynamic>;
        if (guestData['active'] == false) {
          await _auth.signOut();
          return 'Your account has been disabled. Please contact support.';
        }
      }

      // If validation passes, the _onAuthStateChanged listener will automatically trigger _loadUserData.
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e
          .message; // Return Firebase-specific errors (e.g., wrong password)
    } catch (e) {
      await _auth.signOut(); // Sign out on any other error to be safe
      return 'An unexpected error occurred during sign-in.';
    }
  }

  Future<String?> updateAdminProfile({
    required String fName,
    required String lName,
  }) async {
    if (_user == null || _currentAdmin == null) {
      return "User not authenticated.";
    }
    try {
      final updates = {'fName': fName, 'lName': lName};
      await _adminService.updateAdmin(_user!.uid, updates);

      // Also update the local state to reflect changes immediately
      _currentAdmin = Admin(
        adminId: _currentAdmin!.adminId,
        fName: fName,
        lName: lName,
        email: _currentAdmin!.email,
        active: _currentAdmin!.active,
        role: _currentAdmin!.role,
        createdAt: _currentAdmin!.createdAt,
        updatedAt: DateTime.now(),
        hotelId: _currentAdmin!.hotelId,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null || _user!.email == null) {
      return "User not authenticated or email is missing.";
    }

    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Update the password
      await _user!.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific errors like wrong password
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  Future<String?> deleteAccount(String password) async {
    if (_user == null || _user!.email == null) {
      return "User not authenticated or email is missing.";
    }

    try {
      // Re-authenticate the user for security
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Delete the user document from Firestore
      if (_role == 'guest' && _currentGuest != null) {
        await _guestService.deleteGuest(_currentGuest!.guestId);
      } else if (_role == 'admin' && _currentAdmin != null) {
        await _adminService.deleteAdmin(_currentAdmin!.adminId);
      }

      // Delete the user from Firebase Auth
      await _user!.delete();

      // Sign out (though delete should sign out automatically)
      await signOut();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _updateFCMToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = (await FirebaseMessaging.instance.getToken(
          vapidKey:
              "BNyt_eYQtOWDhu9fAEydUVqIN9FiYh4eLFA9RT0YqUmrk52nxzwcXQxNgCXTM_Uq93iWiTnoUAFm-r6VKVO9xoQ",
        ))!;
      } else if (Platform.isAndroid) {
        token = (await FirebaseMessaging.instance.getToken())!;
      }

      print('Token: $token');
      if (_user != null && token != _lastFCMToken) {
        if (_role == 'guest' && _currentGuest != null) {
          await _guestService.updateGuest(_currentGuest!.guestId, {
            'fcmToken': token,
          });
        } else if (_role == 'admin' && _currentAdmin != null) {
          await _adminService.updateAdmin(_currentAdmin!.adminId, {
            'fcmToken': token,
          });
        }
        _lastFCMToken = token;
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
