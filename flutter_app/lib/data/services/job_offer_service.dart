import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/models/job_offer.dart';
import 'package:infojobs_flutter_app/data/services/api_client.dart';

final jobOfferServiceProvider = Provider<JobOfferService>((ref) {
  final client = ref.watch(apiClientProvider);
  return JobOfferService(client);
});

class JobOfferService {
  JobOfferService(this._client);

  final Dio _client;

  Future<List<JobOffer>> fetchJobOffers({String? seniority}) async {
    final response = await _client.get<List<dynamic>>(
      '/offers',
      queryParameters: {
        if (seniority != null && seniority.isNotEmpty)
          'seniority': seniority,
      },
    );

    final data = response.data ?? <dynamic>[];
    return data
        .map((item) => JobOffer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JobOffer> fetchJobOffer(String id) async {
    final response = await _client.get<Map<String, dynamic>>('/offers/$id');
    final data = response.data ?? <String, dynamic>{};
    return JobOffer.fromJson(data);
  }

  Future<JobOffer> createJobOffer(JobOfferPayload payload) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/offers',
      data: payload.toJson(),
    );
    final data = response.data ?? <String, dynamic>{};
    return JobOffer.fromJson(data);
  }
}

class JobOfferPayload {
  const JobOfferPayload({
    required this.companyId,
    required this.title,
    required this.description,
    required this.location,
    required this.seniority,
    required this.remote,
    required this.skills,
  });

  final String companyId;
  final String title;
  final String description;
  final String location;
  final String seniority;
  final bool remote;
  final List<String> skills;

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'title': title,
      'description': description,
      'location': location,
      'seniority': seniority,
      'remote': remote,
      'skills': skills,
    };
  }
}
