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
    return Interview(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String,
      jobOfferId: json['jobOfferId'] as String,
      companyUid: json['companyUid'] as String,
      candidateUid: json['candidateUid'] as String,
      participants: List<String>.from(json['participants'] as List),
      status: InterviewStatus.fromString(json['status'] as String),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      scheduledAt: (json['scheduledAt'] as Timestamp?)?.toDate(),
      timeZone: json['timeZone'] as String?,
      unreadCounts: (json['unreadCounts'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ),
      lastMessage: json['lastMessage'] != null
          ? InterviewLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      meetingLink: json['meetingLink'] as String?,
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
      content: json['content'] as String,
      senderUid: json['senderUid'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
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
