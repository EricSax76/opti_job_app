import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class InterviewMessage extends Equatable {
  const InterviewMessage({
    required this.id,
    required this.senderUid,
    required this.content,
    required this.type,
    required this.createdAt,
    this.metadata,
    this.readByData,
  });

  final String id;
  final String senderUid;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final MessageMetadata? metadata;
  final Map<String, DateTime>? readByData;

  bool get isSystem => type == MessageType.system;
  bool get isProposal => type == MessageType.proposal;

  factory InterviewMessage.fromJson(Map<String, dynamic> json) {
    return InterviewMessage(
      id: json['id'] as String,
      senderUid: json['senderUid'] as String,
      content: json['content'] as String,
      type: MessageType.fromString(json['type'] as String),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      metadata: json['metadata'] != null
          ? MessageMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      readByData: (json['readByData'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderUid': senderUid,
      'content': content,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      if (metadata != null) 'metadata': metadata!.toJson(),
      if (readByData != null)
        'readByData': readByData!.map(
          (key, value) => MapEntry(key, Timestamp.fromDate(value)),
        ),
    };
  }

  @override
  List<Object?> get props => [
        id,
        senderUid,
        content,
        type,
        createdAt,
        metadata,
        readByData,
      ];
}

enum MessageType {
  text('text'),
  proposal('proposal'),
  acceptance('acceptance'),
  rejection('rejection'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageMetadata extends Equatable {
  const MessageMetadata({
    this.proposalId,
    this.proposedAt,
    this.timeZone,
  });

  final String? proposalId;
  final DateTime? proposedAt;
  final String? timeZone;

  factory MessageMetadata.fromJson(Map<String, dynamic> json) {
    return MessageMetadata(
      proposalId: json['proposalId'] as String?,
      proposedAt: (json['proposedAt'] as Timestamp?)?.toDate(),
      timeZone: json['timeZone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (proposalId != null) 'proposalId': proposalId,
      if (proposedAt != null) 'proposedAt': Timestamp.fromDate(proposedAt!),
      if (timeZone != null) 'timeZone': timeZone,
    };
  }

  @override
  List<Object?> get props => [proposalId, proposedAt, timeZone];
}
