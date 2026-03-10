# Job Offer Detail Controller Split

This folder contains the phase-based split of the old monolithic
`JobOfferDetailController`.

## Responsibilities

- `job_offer_detail_feedback_handler.dart`
  - Reads detail state messages and shows snackbars/match result dialogs.
- `job_offer_detail_loading_dialog.dart`
  - Shared blocking loading dialog helper used by async flows.
- `job_offer_detail_match_flow.dart`
  - Match action flow (`computeMatch`).
- `job_offer_detail_apply_flow.dart`
  - End-to-end apply flow orchestration.
- `job_offer_detail_ai_consent_flow.dart`
  - AI consent dialog + consent persistence.
- `job_offer_detail_knockout_flow.dart`
  - Knockout questions parsing and answer collection.
- `job_offer_detail_signature_flow.dart`
  - Qualified signature flow.

`job_offer_detail_controller.dart` remains as a thin facade with the same public
API expected by containers/widgets.

## Maintenance Rules

- Keep business-facing behavior in these flows, not in the facade.
- Guard UI operations after async calls with `context.mounted` checks.
- Treat knockout payloads as untrusted input and parse defensively.

## Regression Checks

Run after any change in this folder:

```bash
flutter test test/modules/job_offers/ui/controllers/job_offer_detail_controller_test.dart
flutter test test/modules/ats/models/knockout_question_test.dart
flutter --suppress-analytics analyze lib/modules/job_offers/ui/controllers lib/modules/ats/models/knockout_question.dart
```
