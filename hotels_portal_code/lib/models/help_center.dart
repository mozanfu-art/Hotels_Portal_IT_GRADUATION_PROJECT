import 'package:cloud_firestore/cloud_firestore.dart';

class HelpCenter {
  final String helpId;
  final String category;
  final String title;
  final String question;
  final String answer;
  final List<String> tags;
  final bool isPublished;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  HelpCenter({
    required this.helpId,
    required this.category,
    required this.title,
    required this.question,
    required this.answer,
    required this.tags,
    required this.isPublished,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpCenter.fromMap(Map<String, dynamic> map) {
    return HelpCenter(
      helpId: map['helpId'],
      category: map['category'],
      title: map['title'],
      question: map['question'],
      answer: map['answer'],
      tags: List<String>.from(map['tags']),
      isPublished: map['isPublished'],
      viewCount: map['viewCount'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'helpId': helpId,
      'category': category,
      'title': title,
      'question': question,
      'answer': answer,
      'tags': tags,
      'isPublished': isPublished,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class HelpCenterResponse {
  final String responseId;
  final DocumentReference helpCenterId;
  final DocumentReference userId;
  final String userType;
  final String response;
  final bool isHelpful;
  final DateTime createdAt;
  final DateTime updatedAt;

  HelpCenterResponse({
    required this.responseId,
    required this.helpCenterId,
    required this.userId,
    required this.userType,
    required this.response,
    required this.isHelpful,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpCenterResponse.fromMap(Map<String, dynamic> map) {
    return HelpCenterResponse(
      responseId: map['responseId'],
      helpCenterId: map['helpCenterId'],
      userId: map['userId'],
      userType: map['userType'],
      response: map['response'],
      isHelpful: map['isHelpful'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'responseId': responseId,
      'helpCenterId': helpCenterId,
      'userId': userId,
      'userType': userType,
      'response': response,
      'isHelpful': isHelpful,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
