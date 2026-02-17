import 'package:equatable/equatable.dart';

class InterviewMessageBubbleViewModel extends Equatable {
  const InterviewMessageBubbleViewModel({
    required this.content,
    required this.isSystem,
    required this.isProposal,
    required this.showProposalActions,
    required this.createdAtText,
    this.proposalDateText,
  });

  final String content;
  final bool isSystem;
  final bool isProposal;
  final bool showProposalActions;
  final String createdAtText;
  final String? proposalDateText;

  @override
  List<Object?> get props => [
    content,
    isSystem,
    isProposal,
    showProposalActions,
    createdAtText,
    proposalDateText,
  ];
}
