import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

void main() {
  final now = DateTime(2026, 3, 4, 12, 0);

  Map<String, dynamic> baseData() => {
    'uid': 'uid-123',
    'companyId': 'company-456',
    'email': 'recruiter@example.com',
    'name': 'Ana García',
    'role': 'recruiter',
    'status': 'active',
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  };

  group('Recruiter', () {
    group('fromFirestore', () {
      test('parses all required fields', () {
        final r = Recruiter.fromFirestore(baseData());
        expect(r.uid, 'uid-123');
        expect(r.companyId, 'company-456');
        expect(r.email, 'recruiter@example.com');
        expect(r.name, 'Ana García');
        expect(r.role, RecruiterRole.recruiter);
        expect(r.status, RecruiterStatus.active);
        expect(r.invitedBy, isNull);
        expect(r.invitedAt, isNull);
        expect(r.acceptedAt, isNull);
        expect(r.createdAt, now);
      });

      test('parses optional fields when present', () {
        final invitedAt = DateTime(2026, 3, 1);
        final data = {
          ...baseData(),
          'invitedBy': 'admin-uid',
          'invitedAt': Timestamp.fromDate(invitedAt),
          'role': 'admin',
          'status': 'invited',
        };
        final r = Recruiter.fromFirestore(data);
        expect(r.invitedBy, 'admin-uid');
        expect(r.invitedAt, invitedAt);
        expect(r.role, RecruiterRole.admin);
        expect(r.status, RecruiterStatus.invited);
      });

      test('unknown role defaults to viewer', () {
        final data = {...baseData(), 'role': 'superAdmin'};
        final r = Recruiter.fromFirestore(data);
        expect(r.role, RecruiterRole.viewer);
      });
    });

    group('toFirestore', () {
      test('round-trip fromFirestore → toFirestore', () {
        final original = Recruiter.fromFirestore(baseData());
        final map = original.toFirestore();
        final restored = Recruiter.fromFirestore(map);
        expect(restored, original);
      });

      test('does not include null optional fields', () {
        final r = Recruiter.fromFirestore(baseData());
        final map = r.toFirestore();
        expect(map.containsKey('invitedBy'), isFalse);
        expect(map.containsKey('invitedAt'), isFalse);
        expect(map.containsKey('acceptedAt'), isFalse);
      });
    });

    group('helpers', () {
      test('isAdmin true for admin role', () {
        final data = {...baseData(), 'role': 'admin'};
        expect(Recruiter.fromFirestore(data).isAdmin, isTrue);
      });
      test('isAdmin false for recruiter role', () {
        expect(Recruiter.fromFirestore(baseData()).isAdmin, isFalse);
      });
      test('isActive true when status=active', () {
        expect(Recruiter.fromFirestore(baseData()).isActive, isTrue);
      });
      test('isActive false when disabled', () {
        final data = {...baseData(), 'status': 'disabled'};
        expect(Recruiter.fromFirestore(data).isActive, isFalse);
      });
    });
  });
}
