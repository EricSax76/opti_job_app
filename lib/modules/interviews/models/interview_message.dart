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
      id: _readString(json['id']),
      senderUid: _readString(json['senderUid'] ?? json['sender_uid']),
      content: _readString(json['content']),
      type: MessageType.fromString(
        _readString(json['type'], fallback: MessageType.text.value),
      ),
      createdAt:
          _parseDateTime(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? MessageMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      readByData: _readByDataMap(json['readByData'] ?? json['read_by_data']),
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
      proposalId: _readNullableString(json['proposalId'] ?? json['proposal_id']),
      proposedAt: _parseDateTime(json['proposedAt'] ?? json['proposed_at']),
      timeZone: _readNullableString(json['timeZone'] ?? json['time_zone']),
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

Map<String, DateTime>? _readByDataMap(dynamic value) {
  if (value is! Map) return null;
  final readBy = <String, DateTime>{};
  value.forEach((key, rawValue) {
    final uid = key.toString().trim();
    if (uid.isEmpty) return;
    final parsed = _parseDateTime(rawValue);
    if (parsed != null) {
      readBy[uid] = parsed;
    }
  });
  return readBy;
}
