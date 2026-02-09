import 'dart:typed_data';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';

class ProfileRepository {
  ProfileRepository(this._service);

  final ProfileService _service;
  final Map<String, Candidate> _candidateCache = <String, Candidate>{};
  final Map<int, Company> _companyCache = <int, Company>{};

  Future<Candidate> fetchCandidateProfile(
    String uid, {
    bool forceRefresh = false,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }

    if (!forceRefresh) {
      final cached = _candidateCache[normalizedUid];
      if (cached != null) return cached;
    }

    final candidate = await _service.fetchCandidateProfile(normalizedUid);
    final candidateUid = candidate.uid.trim();
    final cacheKey = candidateUid.isEmpty ? normalizedUid : candidateUid;
    final resolvedCandidate = candidateUid.isEmpty
        ? candidate.copyWith(uid: normalizedUid)
        : candidate;
    _candidateCache[normalizedUid] = resolvedCandidate;
    _candidateCache[cacheKey] = resolvedCandidate;
    return resolvedCandidate;
  }

  Future<Map<String, Candidate>> fetchCandidateProfilesByUids(
    Iterable<String> uids, {
    bool forceRefresh = false,
  }) async {
    final uniqueUids = uids
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueUids.isEmpty) return const {};

    final result = <String, Candidate>{};
    final missing = <String>[];

    for (final uid in uniqueUids) {
      if (!forceRefresh) {
        final cached = _candidateCache[uid];
        if (cached != null) {
          result[uid] = cached;
          continue;
        }
      }
      missing.add(uid);
    }

    if (missing.isNotEmpty) {
      final fetched = await _service.fetchCandidateProfilesByUids(missing);
      for (final entry in fetched.entries) {
        final uid = entry.key.trim();
        if (uid.isEmpty) continue;
        _candidateCache[uid] = entry.value;
      }
      for (final uid in missing) {
        final candidate = _candidateCache[uid];
        if (candidate != null) {
          result[uid] = candidate;
        }
      }
    }

    return result;
  }

  Future<Company> fetchCompanyProfile(
    int id, {
    bool forceRefresh = false,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'must be greater than 0');
    }

    if (!forceRefresh) {
      final cached = _companyCache[id];
      if (cached != null) return cached;
    }

    final company = await _service.fetchCompanyProfile(id);
    _companyCache[id] = company;
    return company;
  }

  Future<Map<int, Company>> fetchCompaniesByIds(
    List<int> ids, {
    bool forceRefresh = false,
  }) async {
    final uniqueIds = ids.where((id) => id > 0).toSet().toList();
    if (uniqueIds.isEmpty) return const {};

    final result = <int, Company>{};
    final missing = <int>[];
    for (final id in uniqueIds) {
      if (!forceRefresh) {
        final cached = _companyCache[id];
        if (cached != null) {
          result[id] = cached;
          continue;
        }
      }
      missing.add(id);
    }

    if (missing.isNotEmpty) {
      final fetched = await _service.fetchCompaniesByIds(missing);
      for (final entry in fetched.entries) {
        _companyCache[entry.key] = entry.value;
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  Future<Candidate> updateCandidateProfile({
    required String uid,
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
  }) async {
    final updated = await _service.updateCandidateProfile(
      uid: uid,
      name: name,
      lastName: lastName,
      avatarBytes: avatarBytes,
    );
    final normalizedUid = updated.uid.trim().isEmpty ? uid.trim() : updated.uid;
    final resolved = updated.copyWith(uid: normalizedUid);
    _candidateCache[uid.trim()] = resolved;
    _candidateCache[normalizedUid] = resolved;
    return _candidateCache[normalizedUid]!;
  }

  Future<Company> updateCompanyProfile({
    required String uid,
    required String name,
    Uint8List? avatarBytes,
  }) async {
    final updated = await _service.updateCompanyProfile(
      uid: uid,
      name: name,
      avatarBytes: avatarBytes,
    );
    if (updated.id > 0) {
      _companyCache[updated.id] = updated;
    }
    return updated;
  }
}
