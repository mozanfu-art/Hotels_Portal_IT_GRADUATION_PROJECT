import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/admin.dart';
import 'package:hotel_booking_app/models/help_center.dart';
import 'package:hotel_booking_app/models/notification.dart';
import 'package:hotel_booking_app/models/report.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin CRUD Operations
  Future<Admin?> getAdmin(String adminId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('admins')
          .doc(adminId)
          .get();
      if (doc.exists) {
        return Admin.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get admin: $e');
    }
  }

  Future<List<Admin>> getAllAdmins() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('admins').get();
      return snapshot.docs
          .map((doc) => Admin.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get admins: $e');
    }
  }

  Future<String> createAdmin(Admin admin) async {
    try {
      // Ensure hotelId is provided for hotel admins
      if (admin.role == 'hotel admin' && (admin.hotelId?.isEmpty ?? true)) {
        throw Exception('Hotel ID is required for hotel admin creation');
      }
      await _firestore
          .collection('admins')
          .doc(admin.adminId)
          .set(admin.toMap());
      return admin.adminId;
    } catch (e) {
      throw Exception('Failed to create admin: $e');
    }
  }

  Future<void> updateAdmin(String adminId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update admin: $e');
    }
  }

  Future<void> updateAdminSettings(
    String adminId,
    Map<String, dynamic> settingsData,
  ) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'settings': settingsData,
      });
    } catch (e) {
      throw Exception('Failed to update admin settings: $e');
    }
  }

  Future<void> deleteAdmin(String adminId) async {
    try {
      await _firestore.collection('admins').doc(adminId).delete();
    } catch (e) {
      throw Exception('Failed to delete admin: $e');
    }
  }

  // Hotel Management
  Stream<QuerySnapshot> getAllHotels() {
    return _firestore
        .collection('hotels')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Help Center Management
  Future<List<HelpCenter>> getHelpCenterArticles() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('help_center').get();
      return snapshot.docs
          .map((doc) => HelpCenter.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get help center articles: $e');
    }
  }

  Future<String> createHelpCenterArticle(HelpCenter article) async {
    try {
      await _firestore
          .collection('help_center')
          .doc(article.helpId)
          .set(article.toMap());
      return article.helpId;
    } catch (e) {
      throw Exception('Failed to create help center article: $e');
    }
  }

  Future<void> updateHelpCenterArticle(
    String helpId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('help_center').doc(helpId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update help center article: $e');
    }
  }

  Future<void> deleteHelpCenterArticle(String helpId) async {
    try {
      await _firestore.collection('help_center').doc(helpId).delete();
    } catch (e) {
      throw Exception('Failed to delete help center article: $e');
    }
  }

  // Help Center Responses
  Future<List<HelpCenterResponse>> getHelpCenterResponses(String helpId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('help_center')
          .doc(helpId)
          .collection('responses')
          .get();
      return snapshot.docs
          .map(
            (doc) =>
                HelpCenterResponse.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get help center responses: $e');
    }
  }

  Future<String> addHelpCenterResponse(
    String helpId,
    HelpCenterResponse response,
  ) async {
    try {
      await _firestore
          .collection('help_center')
          .doc(helpId)
          .collection('responses')
          .doc(response.responseId)
          .set(response.toMap());
      return response.responseId;
    } catch (e) {
      throw Exception('Failed to add help center response: $e');
    }
  }

  Future<void> updateHelpCenterResponse(
    String helpId,
    String responseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection('help_center')
          .doc(helpId)
          .collection('responses')
          .doc(responseId)
          .update({...updates, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to update help center response: $e');
    }
  }

  Future<void> deleteHelpCenterResponse(
    String helpId,
    String responseId,
  ) async {
    try {
      await _firestore
          .collection('help_center')
          .doc(helpId)
          .collection('responses')
          .doc(responseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete help center response: $e');
    }
  }

  // Report Generation
  Future<String> createReport(Report report) async {
    try {
      await _firestore
          .collection('reports')
          .doc(report.reportId)
          .set(report.toMap());
      return report.reportId;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  Future<List<Report>> getReports() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Admin Notifications
  Future<List<Notification>> getAdminNotifications(String adminId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where(
            'userId',
            isEqualTo: _firestore.collection('admins').doc(adminId),
          )
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => Notification.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get admin notifications: $e');
    }
  }

  Future<String> addAdminNotification(
    String adminId,
    Notification notification,
  ) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap());
      return notification.notificationId;
    } catch (e) {
      throw Exception('Failed to add admin notification: $e');
    }
  }

  Future<void> markAdminNotificationAsRead(
    String adminId,
    String notificationId,
  ) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to mark admin notification as read: $e');
    }
  }

  Future<void> deleteAdminNotification(
    String adminId,
    String notificationId,
  ) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete admin notification: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<Notification>> getAdminNotificationsStream(String adminId) {
    return _firestore
        .collection('notifications')
        .where(
          'userId',
          isEqualTo: _firestore.collection('admins').doc(adminId),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notification.fromMap(doc.data()))
              .toList(),
        );
  }
}
