import 'dart:typed_data';
import 'package:opti_job_app/modules/companies/models/company.dart';

abstract class CompaniesRepository {
  Future<Company> fetchCompanyProfile(int id);
  Future<Map<int, Company>> fetchCompaniesByIds(List<int> ids);
  Future<Company> updateCompanyProfile({
    required String uid,
    required String name,
    Uint8List? avatarBytes,
  });
}
