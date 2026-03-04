import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

void main() {
  group('RecruiterRole', () {
    group('fromString', () {
      test('admin', () {
        expect(RecruiterRole.fromString('admin'), RecruiterRole.admin);
      });
      test('recruiter', () {
        expect(RecruiterRole.fromString('recruiter'), RecruiterRole.recruiter);
      });
      test('viewer', () {
        expect(RecruiterRole.fromString('viewer'), RecruiterRole.viewer);
      });
      test('unknown defaults to viewer', () {
        expect(RecruiterRole.fromString('superAdmin'), RecruiterRole.viewer);
      });
      test('empty string defaults to viewer', () {
        expect(RecruiterRole.fromString(''), RecruiterRole.viewer);
      });
    });

    group('toFirestoreString', () {
      test('admin', () {
        expect(RecruiterRole.admin.toFirestoreString(), 'admin');
      });
      test('recruiter', () {
        expect(RecruiterRole.recruiter.toFirestoreString(), 'recruiter');
      });
      test('viewer', () {
        expect(RecruiterRole.viewer.toFirestoreString(), 'viewer');
      });
    });

    test('round-trip fromString → toFirestoreString', () {
      for (final role in RecruiterRole.values) {
        final str = role.toFirestoreString();
        expect(RecruiterRole.fromString(str), role);
      }
    });
  });
}
