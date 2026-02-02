import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratedReport {
  final String id;
  final String reportType;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final String generatedBy; // Admin User ID
  final String reportDataJson; // Store the report data as a JSON string

  GeneratedReport({
    required this.id,
    required this.reportType,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.generatedBy,
    required this.reportDataJson,
  });

  factory GeneratedReport.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GeneratedReport(
      id: doc.id,
      reportType: data['reportType'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      generatedBy: data['generatedBy'] ?? '',
      reportDataJson: data['reportDataJson'] ?? '{}',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportType': reportType,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'generatedBy': generatedBy,
      'reportDataJson': reportDataJson,
    };
  }
}
