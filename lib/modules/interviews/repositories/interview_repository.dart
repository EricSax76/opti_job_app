import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';

abstract class InterviewRepository {
  /// Stream of interviews for a given user (company or candidate)
  Stream<List<Interview>> interviewsStream(String uid);

  /// Stream of a specific interview by ID
  Stream<Interview?> interviewStream(String interviewId);

  /// Stream of messages for a specific interview
  Stream<List<InterviewMessage>> messagesStream(String interviewId);

  /// Starts an interview for an application (Company only)
  /// Returns the interviewId
  Future<String> startInterview(String applicationId);

  /// Sends a message in an interview
  Future<void> sendMessage({
    required String interviewId,
    required String content,
    MessageType type = MessageType.text,
    MessageMetadata? metadata,
  });

  /// Proposes a time slot for the interview
  Future<void> proposeSlot({
    required String interviewId,
    required DateTime proposedAt,
    required String timeZone,
  });

  /// Responds to a proposed time slot
  Future<void> respondToSlot({
    required String interviewId,
    required String proposalId,
    required bool accept,
  });

  /// Marks an interview as seen by the user
  Future<void> markAsSeen(String interviewId);

  /// Cancels an interview
  Future<void> cancelInterview(String interviewId, {String? reason});

  /// Completes an interview
  Future<void> completeInterview(String interviewId, {String? notes});
  /// Starts a meeting for the interview
  Future<void> startMeeting({
    required String interviewId,
    required String meetingLink,
  });
}
