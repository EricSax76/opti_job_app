import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';

void main() {
  test('fromJson uses defaults when settings are missing', () {
    final settings = CompanyMultipostingSettings.fromJson(null);
    expect(settings.enabledChannels, companyDefaultMultipostingChannels);
  });

  test('fromJson preserves explicit empty enabledChannels', () {
    final settings = CompanyMultipostingSettings.fromJson({
      'enabledChannels': <String>[],
    });
    expect(settings.enabledChannels, isEmpty);
  });

  test('fromJson preserves explicit all-disabled channels config', () {
    final settings = CompanyMultipostingSettings.fromJson({
      'channels': {
        'linkedin': {'enabled': false},
        'indeed': {'enabled': false},
      },
    });
    expect(settings.enabledChannels, isEmpty);
  });
}
