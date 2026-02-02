import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_booking_app/models/activity.dart';

class ActivityService {
  final CollectionReference _activitiesCollection = FirebaseFirestore.instance
      .collection('activities');

  Future<void> createActivity(Activity activity) async {
    await _activitiesCollection.add(activity.toMap());
  }

  Stream<List<Activity>> getRecentActivitiesStream({int limit = 5}) {
    return _activitiesCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Activity.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  Future<List<Activity>> getAllActivities({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? filterByType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _activitiesCollection.orderBy('timestamp', descending: true);

    if (filterByType != null) {
      query = query.where('type', isEqualTo: filterByType);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => Activity.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }
}
