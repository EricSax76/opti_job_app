import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:infojobs_flutter_app/backend/data/repositories/job_offer_repository.dart';
import 'package:infojobs_flutter_app/backend/utils/response.dart';

class JobOffersRouter {
  JobOffersRouter(this._repository);

  final JobOfferRepository _repository;

  Router get router {
    final router = Router();
    router.get('/', _handleGetAll);
    router.get('/<id|[0-9]+>', _handleGetById);
    router.post('/', _handleCreate);
    return router;
  }

  Future<Response> _handleGetAll(Request request) async {
    final jobType = request.requestedUri.queryParameters['job_type'];
    final offers = await _repository.findAll(jobType: jobType);
    return jsonResponse(offers.map((offer) => offer.toJson()).toList());
  }

  Future<Response> _handleGetById(Request request, String id) async {
    final offer = await _repository.findById(int.parse(id));
    if (offer == null) {
      return jsonError('Offer not found', statusCode: 404);
    }
    return jsonResponse(offer.toJson());
  }

  Future<Response> _handleCreate(Request request) async {
    final body = await request.readAsString();
    final payload = jsonDecode(body) as Map<String, dynamic>;

    if (payload['title'] == null || payload['description'] == null) {
      return jsonError('title y description son obligatorios');
    }
    final jobOffer = await _repository.create(
      title: payload['title'] as String,
      description: payload['description'] as String,
      location: payload['location'] as String? ?? '',
      salaryMin: _normalizeSalary(payload['salary_min']),
      salaryMax: _normalizeSalary(payload['salary_max']),
      education: payload['education'] as String?,
      jobType: payload['job_type'] as String?,
    );

    return jsonResponse(jobOffer.toJson(), statusCode: 201);
  }
}

num? _normalizeSalary(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return num.tryParse(digits);
  }
  return null;
}
