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

  Future<List<JobOffer>> fetchJobOffers({String? jobType}) async {
    final response = await _client.get<List<dynamic>>(
      '/job_offers',
      queryParameters: {
        if (jobType != null && jobType.isNotEmpty) 'job_type': jobType,
      },
    );

    final data = response.data ?? <dynamic>[];
    return data
        .map((item) => JobOffer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JobOffer> fetchJobOffer(int id) async {
    final response =
        await _client.get<Map<String, dynamic>>('/job_offers/$id');
    final data = response.data ?? <String, dynamic>{};
    return JobOffer.fromJson(data);
  }

  Future<JobOffer> createJobOffer(JobOfferPayload payload) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/job_offers',
      data: payload.toJson(),
    );
    final data = response.data ?? <String, dynamic>{};
    return JobOffer.fromJson(data);
  }
}

class JobOfferPayload {
  const JobOfferPayload({
    required this.title,
    required this.description,
    required this.location,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.jobType,
  });

  final String title;
  final String description;
  final String location;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? jobType;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'job_type': jobType,
    };
  }
}
