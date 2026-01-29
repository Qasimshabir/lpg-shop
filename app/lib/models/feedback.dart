class Feedback {
  final String id;
  final String category;
  final String title;
  final String message;
  final String priority;
  final String status;
  final String? adminResponse;
  final DateTime? responseDate;
  final List<String> screenshots;
  final DeviceInfo? deviceInfo;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    this.priority = 'medium',
    this.status = 'pending',
    this.adminResponse,
    this.responseDate,
    this.screenshots = const [],
    this.deviceInfo,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['_id'] ?? '',
      category: json['category'] ?? 'general',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      adminResponse: json['adminResponse'],
      responseDate: json['responseDate'] != null 
          ? DateTime.parse(json['responseDate'])
          : null,
      screenshots: List<String>.from(json['screenshots'] ?? []),
      deviceInfo: json['deviceInfo'] != null 
          ? DeviceInfo.fromJson(json['deviceInfo'])
          : null,
      isPublic: json['isPublic'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category,
      'title': title,
      'message': message,
      'priority': priority,
      'status': status,
      'adminResponse': adminResponse,
      'responseDate': responseDate?.toIso8601String(),
      'screenshots': screenshots,
      'deviceInfo': deviceInfo?.toJson(),
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String get categoryDisplayText {
    switch (category) {
      case 'bug':
        return 'Bug Report';
      case 'feature':
        return 'Feature Request';
      case 'general':
        return 'General Feedback';
      case 'complaint':
        return 'Complaint';
      case 'suggestion':
        return 'Suggestion';
      default:
        return 'Other';
    }
  }

  String get priorityDisplayText {
    switch (priority) {
      case 'low':
        return 'Low Priority';
      case 'medium':
        return 'Medium Priority';
      case 'high':
        return 'High Priority';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  bool get isResolved => status == 'resolved';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;
}

class DeviceInfo {
  final String? platform;
  final String? version;
  final String? model;

  DeviceInfo({
    this.platform,
    this.version,
    this.model,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'],
      version: json['version'],
      model: json['model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'version': version,
      'model': model,
    };
  }
}

// Predefined categories
class FeedbackCategories {
  static const List<Map<String, String>> categories = [
    {'value': 'bug', 'label': 'Bug Report'},
    {'value': 'feature', 'label': 'Feature Request'},
    {'value': 'general', 'label': 'General Feedback'},
    {'value': 'complaint', 'label': 'Complaint'},
    {'value': 'suggestion', 'label': 'Suggestion'},
  ];
}

// Predefined priorities
class FeedbackPriorities {
  static const List<Map<String, String>> priorities = [
    {'value': 'low', 'label': 'Low Priority'},
    {'value': 'medium', 'label': 'Medium Priority'},
    {'value': 'high', 'label': 'High Priority'},
    {'value': 'critical', 'label': 'Critical'},
  ];
}
