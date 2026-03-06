import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';

Recruiter makeRecruiter({
  RecruiterRole role = RecruiterRole.recruiter,
  RecruiterStatus status = RecruiterStatus.active,
  String companyId = 'company-test',
}) {
  final now = DateTime(2026, 3, 4);
  return Recruiter(
    uid: 'uid-test',
    companyId: companyId,
    email: 'test@example.com',
    name: 'Test Recruiter',
    role: role,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const rbac = RbacService();

  group('RbacService', () {
    group('null recruiter', () {
      test(
        'canManageOffers is false',
        () => expect(rbac.canManageOffers(null), isFalse),
      );
      test('canScore is false', () => expect(rbac.canScore(null), isFalse));
      test(
        'canViewReports is false',
        () => expect(rbac.canViewReports(null), isFalse),
      );
      test(
        'canManageTeam is false',
        () => expect(rbac.canManageTeam(null), isFalse),
      );
      test(
        'canInviteMembers is false',
        () => expect(rbac.canInviteMembers(null), isFalse),
      );
    });

    group('admin role', () {
      final admin = makeRecruiter(role: RecruiterRole.admin);
      test(
        'canManageOffers',
        () => expect(rbac.canManageOffers(admin), isTrue),
      );
      test('canScore', () => expect(rbac.canScore(admin), isTrue));
      test('canViewReports', () => expect(rbac.canViewReports(admin), isTrue));
      test('canManageTeam', () => expect(rbac.canManageTeam(admin), isTrue));
      test(
        'canInviteMembers',
        () => expect(rbac.canInviteMembers(admin), isTrue),
      );
    });

    group('recruiter role', () {
      final recruiter = makeRecruiter(role: RecruiterRole.recruiter);
      test(
        'canManageOffers',
        () => expect(rbac.canManageOffers(recruiter), isTrue),
      );
      test('canScore', () => expect(rbac.canScore(recruiter), isTrue));
      test(
        'canViewReports',
        () => expect(rbac.canViewReports(recruiter), isTrue),
      );
      test(
        'canManageTeam is false',
        () => expect(rbac.canManageTeam(recruiter), isFalse),
      );
      test(
        'canInviteMembers is false',
        () => expect(rbac.canInviteMembers(recruiter), isFalse),
      );
    });

    group('viewer role', () {
      final viewer = makeRecruiter(role: RecruiterRole.viewer);
      test(
        'canManageOffers is false',
        () => expect(rbac.canManageOffers(viewer), isFalse),
      );
      test('canScore is false', () => expect(rbac.canScore(viewer), isFalse));
      test('canViewReports', () => expect(rbac.canViewReports(viewer), isTrue));
      test(
        'canManageTeam is false',
        () => expect(rbac.canManageTeam(viewer), isFalse),
      );
      test(
        'canInviteMembers is false',
        () => expect(rbac.canInviteMembers(viewer), isFalse),
      );
    });

    group('disabled recruiter', () {
      final disabled = makeRecruiter(
        role: RecruiterRole.admin,
        status: RecruiterStatus.disabled,
      );
      test('all permissions denied even for admin when disabled', () {
        expect(rbac.canManageOffers(disabled), isFalse);
        expect(rbac.canScore(disabled), isFalse);
        expect(rbac.canViewReports(disabled), isFalse);
        expect(rbac.canManageTeam(disabled), isFalse);
        expect(rbac.canInviteMembers(disabled), isFalse);
      });
    });

    group('freelance recruiter (sin empresa)', () {
      final freelance = makeRecruiter(role: RecruiterRole.admin, companyId: '');

      test('all company-scoped permissions are denied', () {
        expect(rbac.canManageOffers(freelance), isFalse);
        expect(rbac.canScore(freelance), isFalse);
        expect(rbac.canViewReports(freelance), isFalse);
        expect(rbac.canManageTeam(freelance), isFalse);
        expect(rbac.canInviteMembers(freelance), isFalse);
      });
    });
  });
}
