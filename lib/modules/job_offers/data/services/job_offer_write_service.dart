import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer_payload.dart';

class JobOfferWriteService {
  JobOfferWriteService({
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _callables = CallableWithFallback(
         functions:
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
         fallbackFunctions: fallbackFunctions ?? FirebaseFunctions.instance,
       );

  final CallableWithFallback _callables;

  Future<String> createJobOffer(JobOfferPayload payload) async {
    final payloadData = payload.toJson();
    return _createOfferSecure(payloadData);
  }

  Future<String> _createOfferSecure(Map<String, dynamic> payload) async {
    final result = await _callables.call<dynamic>(
      name: 'createJobOfferSecure',
      payload: payload,
    );
    return _extractOfferIdFromResult(result);
  }

  String _extractOfferIdFromResult(HttpsCallableResult<dynamic> result) {
    final data = result.data;
    if (data is Map) {
      final id = data['offerId']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    throw StateError('createJobOfferSecure did not return a valid offerId.');
  }
}
