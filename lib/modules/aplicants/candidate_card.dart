import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/companies/models/company_candidates_logic.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate});

  final CandidateGroup candidate;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: candidate.entries.isEmpty
            ? null
            : () => _openCvPicker(context, candidate),
        leading: CircleAvatar(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          child: Text(candidate.displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          candidate.displayName,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          candidate.entries.map((e) => e.offerTitle).join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: muted, height: 1.35),
        ),
        trailing: TextButton(
          onPressed: candidate.entries.isEmpty
              ? null
              : () => _openCvPicker(context, candidate),
          child: const Text('CV'),
        ),
      ),
    );
  }

  void _openCvPicker(BuildContext context, CandidateGroup candidate) {
    if (candidate.entries.length == 1) {
      final entry = candidate.entries.first;
      context.push(
        '/company/offers/${entry.offerId}/applicants/${candidate.candidateUid}/cv',
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ListTile(
                title: Text(
                  candidate.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Selecciona una oferta para ver el CV'),
              ),
              const SizedBox(height: 6),
              for (final entry in candidate.entries)
                Card(
                  child: ListTile(
                    title: Text(entry.offerTitle),
                    subtitle: Text('Estado: ${_statusLabel(entry.status)}'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        '/company/offers/${entry.offerId}/applicants/${candidate.candidateUid}/cv',
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'reviewing':
        return 'En revisión';
      case 'interview':
        return 'Entrevista';
      case 'accepted':
        return 'Aceptado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }
}
