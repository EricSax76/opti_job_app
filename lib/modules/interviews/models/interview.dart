import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Interview extends Equatable {
  const Interview({
    required this.id,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyUid,
    required this.candidateUid,
    required this.participants,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.timeZone,
    this.unreadCounts,
    this.lastMessage,
    this.meetingLink,
  });

  final String id;
  final String applicationId;
  final String jobOfferId;
  final String companyUid;
  final String candidateUid;
  final List<String> participants;
  final InterviewStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;
  final String? timeZone;
  final Map<String, int>? unreadCounts;
  final InterviewLastMessage? lastMessage;
  final String? meetingLink;

  factory Interview.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDateTime(json['createdAt'] ?? json['created_at']);
    final updatedAt = _parseDateTime(json['updatedAt'] ?? json['updated_at']);
    return Interview(
      id: _readString(json['id']),
      applicationId: _readString(
        json['applicationId'] ?? json['application_id'],
      ),
      jobOfferId: _readString(json['jobOfferId'] ?? json['job_offer_id']),
      companyUid: _readString(json['companyUid'] ?? json['company_uid']),
      candidateUid: _readString(
        json['candidateUid'] ??
            json['candidate_uid'] ??
            json['candidateId'] ??
            json['candidate_id'],
      ),
      participants: _readStringList(json['participants']),
      status: InterviewStatus.fromString(
        _readString(json['status'], fallback: InterviewStatus.scheduling.value),
      ),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
      scheduledAt: _parseDateTime(json['scheduledAt'] ?? json['scheduled_at']),
      timeZone: _readNullableString(json['timeZone'] ?? json['time_zone']),
      unreadCounts: _readUnreadCounts(json['unreadCounts']),
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? InterviewLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      meetingLink: _readNullableString(json['meetingLink'] ?? json['meeting_link']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicationId': applicationId,
      'jobOfferId': jobOfferId,
      'companyUid': companyUid,
      'candidateUid': candidateUid,
      'participants': participants,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      if (timeZone != null) 'timeZone': timeZone,
      if (unreadCounts != null) 'unreadCounts': unreadCounts,
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      if (meetingLink != null) 'meetingLink': meetingLink,
    };
  }
  
  Interview copyWith({
    String? id,
    String? applicationId,
    String? jobOfferId,
    String? companyUid,
    String? candidateUid,
    List<String>? participants,
    InterviewStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    String? timeZone,
    Map<String, int>? unreadCounts,
    InterviewLastMessage? lastMessage,
    String? meetingLink,
  }) {
    return Interview(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      jobOfferId: jobOfferId ?? this.jobOfferId,
      companyUid: companyUid ?? this.companyUid,
      candidateUid: candidateUid ?? this.candidateUid,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timeZone: timeZone ?? this.timeZone,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastMessage: lastMessage ?? this.lastMessage,
      meetingLink: meetingLink ?? this.meetingLink,
    );
  }

  @override
  List<Object?> get props => [
        id,
        applicationId,
        jobOfferId,
        companyUid,
        candidateUid,
        participants,
        status,
        createdAt,
        updatedAt,
        scheduledAt,
        timeZone,
        unreadCounts,
        lastMessage,
        meetingLink,
      ];
}

enum InterviewStatus {
  scheduling('scheduling'),
  scheduled('scheduled'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const InterviewStatus(this.value);

  static InterviewStatus fromString(String value) {
    return InterviewStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InterviewStatus.scheduling,
    );
  }
}

class InterviewLastMessage extends Equatable {
  const InterviewLastMessage({
    required this.content,
    required this.senderUid,
    required this.createdAt,
  });

  final String content;
  final String senderUid;
  final DateTime createdAt;

  factory InterviewLastMessage.fromJson(Map<String, dynamic> json) {
    return InterviewLastMessage(
      content: _readString(json['content']),
      senderUid: _readString(json['senderUid'] ?? json['sender_uid']),
      createdAt:
          _parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderUid': senderUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [content, senderUid, createdAt];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? fallback : normalized;
}

String? _readNullableString(dynamic value) {
  final normalized = _readString(value);
  return normalized.isEmpty ? null : normalized;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

Map<String, int>? _readUnreadCounts(dynamic value) {
  if (value is! Map) return null;
  final result = <String, int>{};
  value.forEach((key, rawValue) {
    final id = key.toString().trim();
    if (id.isEmpty) return;
    if (rawValue is int) {
      result[id] = rawValue;
      return;
    }
    if (rawValue is num) {
      result[id] = rawValue.toInt();
      return;
    }
    if (rawValue is String) {
      final parsed = int.tryParse(rawValue);
      if (parsed != null) result[id] = parsed;
    }
  });
  return result;
}
