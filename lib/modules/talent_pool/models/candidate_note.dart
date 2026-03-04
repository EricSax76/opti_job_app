import 'package:equatable/equatable.dart';

enum NoteType {
  general,
  interview,
  evaluation;

  static NoteType fromString(String value) {
    return NoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteType.general,
    );
  }
}

class CandidateNote extends Equatable {
  const CandidateNote({
    required this.id,
    required this.candidateUid,
    required this.companyId,
    required this.recruiterUid,
    required this.recruiterName,
    required this.content,
    this.type = NoteType.general,
    this.isPrivate = false,
    this.createdAt,
  });

  final String id;
  final String candidateUid;
  final String companyId;
  final String recruiterUid;
  final String recruiterName;
  final String content;
  final NoteType type;
  final bool isPrivate;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        candidateUid,
        companyId,
        recruiterUid,
        recruiterName,
        content,
        type,
        isPrivate,
        createdAt,
      ];

  factory CandidateNote.fromJson(Map<String, dynamic> json, {String? id}) {
    return CandidateNote(
      id: id ?? json['id']?.toString() ?? '',
      candidateUid: json['candidateUid'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      recruiterUid: json['recruiterUid'] as String? ?? '',
      recruiterName: json['recruiterName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: NoteType.fromString(json['type'] as String? ?? 'general'),
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateUid': candidateUid,
      'companyId': companyId,
      'recruiterUid': recruiterUid,
      'recruiterName': recruiterName,
      'content': content,
      'type': type.name,
      'isPrivate': isPrivate,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
