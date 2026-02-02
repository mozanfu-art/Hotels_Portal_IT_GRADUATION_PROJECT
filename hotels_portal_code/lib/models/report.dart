import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reportId;
  final String reportType;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DocumentReference reportedBy;
  final DocumentReference? assignedTo;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  Report({
    required this.reportId,
    required this.reportType,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.reportedBy,
    this.assignedTo,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      reportId: map['reportId'],
      reportType: map['reportType'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      priority: map['priority'],
      reportedBy: map['reportedBy'],
      assignedTo: map['assignedTo'],
      metadata: map['metadata'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reportType': reportType,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'reportedBy': reportedBy,
      'assignedTo': assignedTo,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}
