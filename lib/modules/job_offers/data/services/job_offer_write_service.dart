import 'package:cloud_functions/cloud_functions.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer_payload.dart';

class JobOfferWriteService {
  JobOfferWriteService({
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _fallbackFunctions = fallbackFunctions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;

  Future<String> createJobOffer(JobOfferPayload payload) async {
    final payloadData = payload.toJson();
    return _createOfferSecure(payloadData);
  }

  Future<String> _createOfferSecure(Map<String, dynamic> payload) async {
    try {
      final result = await _functions
          .httpsCallable('createJobOfferSecure')
          .call(payload);
      return _extractOfferIdFromResult(result);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') {
        rethrow;
      }
      final fallbackResult = await _fallbackFunctions
          .httpsCallable('createJobOfferSecure')
          .call(payload);
      return _extractOfferIdFromResult(fallbackResult);
    }
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
