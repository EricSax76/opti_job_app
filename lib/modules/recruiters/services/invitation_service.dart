import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/recruiters/models/invitation.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Servicio cliente para gestión de invitaciones de reclutadores.
///
/// La generación y aceptación de invitaciones en producción se delega a
/// Cloud Functions para garantizar seguridad y atomicidad. Este servicio
/// ofrece los métodos equivalentes para entornos de test (emulador) y
/// como wrapper de lectura en cliente.
class InvitationService {
  InvitationService({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  static const _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin 0/O/I/1 para evitar confusión
  static const _codeLength = 6;
  static const _expiryHours = 72;

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('invitations');

  // ─── Generación ──────────────────────────────────────────────────────────

  /// Genera un código alfanumérico de [_codeLength] caracteres seguro.
  String generateCode() {
    final rng = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _chars[rng.nextInt(_chars.length)],
    ).join();
  }

  /// Crea una invitación en Firestore (path: `invitations/{code}`).
  ///
  /// Usa preferentemente la Cloud Function `createInvitation` en producción.
  Future<Invitation> createInvitation({
    required String companyId,
    required RecruiterRole role,
    required String createdBy,
    String? email,
  }) async {
    final code = generateCode();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: _expiryHours));

    final invitation = Invitation(
      code: code,
      companyId: companyId,
      role: role,
      email: email,
      createdBy: createdBy,
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _invitations.doc(code).set(invitation.toFirestore());
    return invitation;
  }

  // ─── Validación ──────────────────────────────────────────────────────────

  /// Lee y valida un código de invitación.
  ///
  /// Devuelve la [Invitation] si es válida, o `null` si el código no existe,
  /// ya fue usado o está caducado.
  Future<Invitation?> validateCode(String code) async {
    final doc = await _invitations.doc(code.toUpperCase()).get();
    if (!doc.exists || doc.data() == null) return null;

    final invitation = Invitation.fromFirestore({
      ...doc.data()!,
      'code': doc.id,
    });
    return invitation.isPending ? invitation : null;
  }

  // ─── Aceptación (solo emulador / tests) ──────────────────────────────────

  /// Marca la invitación como aceptada.
  ///
  /// En producción usa la Cloud Function `acceptInvitation`.
  Future<void> markAccepted(String code, String usedBy) async {
    await _invitations.doc(code.toUpperCase()).update({
      'status': 'accepted',
      'usedBy': usedBy,
    });
  }
}
