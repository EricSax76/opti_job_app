import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/talent_pool/cubits/talent_pool_detail_cubit.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';
import 'package:opti_job_app/modules/talent_pool/ui/widgets/pool_member_card.dart';
import 'package:opti_job_app/modules/talent_pool/ui/widgets/talent_search_bar.dart';

class TalentPoolDetailScreen extends StatefulWidget {
  const TalentPoolDetailScreen({super.key, required this.pool});

  final TalentPool pool;

  @override
  State<TalentPoolDetailScreen> createState() => _TalentPoolDetailScreenState();
}

class _TalentPoolDetailScreenState extends State<TalentPoolDetailScreen> {
  String _searchQuery = '';
  bool _isAddingMember = false;

  @override
  void initState() {
    super.initState();
    context.read<TalentPoolDetailCubit>().subscribeToMembers(widget.pool.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pool.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAddingMember ? null : _showAddMemberDialog,
        icon: _isAddingMember
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_alt_1),
        label: const Text('Añadir candidato'),
      ),
      body: Column(
        children: [
          TalentSearchBar(
            onSearch: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
          Expanded(
            child: BlocBuilder<TalentPoolDetailCubit, TalentPoolDetailState>(
              builder: (context, state) {
                if (state.status == TalentPoolDetailStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == TalentPoolDetailStatus.failure) {
                  return const StateMessage(
                    title: 'Error cargando miembros',
                    message: 'No se pudieron recuperar los miembros del pool.',
                  );
                }

                final filteredMembers = state.members.where((m) {
                  final matchesId = m.candidateUid.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchesTags = m.tags.any(
                    (t) => t.toLowerCase().contains(_searchQuery),
                  );
                  return matchesId || matchesTags;
                }).toList();

                if (filteredMembers.isEmpty) {
                  return const StateMessage(
                    title: 'Sin resultados',
                    message: 'No se encontraron miembros para esta búsqueda.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return PoolMemberCard(
                      member: member,
                      onTap: () {
                        // TODO: Navigate to candidate CRM profile
                      },
                      onRemove: () =>
                          _removeMemberFromPool(member.candidateUid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final candidateUidController = TextEditingController();
    final tagsController = TextEditingController();

    try {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Añadir candidato al pool'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: candidateUidController,
                decoration: const InputDecoration(
                  labelText: 'Candidate UID',
                  hintText: 'uid_del_candidato',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (opcional)',
                  hintText: 'priority, frontend, potential',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Añadir'),
            ),
          ],
        ),
      );

      if (shouldAdd != true || !mounted) return;

      final candidateUid = candidateUidController.text.trim();
      if (candidateUid.isEmpty) {
        _showMessage('Debes indicar un Candidate UID.');
        return;
      }

      final tags = tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final actorUid = context.read<FirebaseAuth>().currentUser?.uid ?? '';
      if (actorUid.isEmpty) {
        _showMessage('No se pudo resolver el usuario autenticado.');
        return;
      }

      setState(() => _isAddingMember = true);
      await context.read<TalentPoolDetailCubit>().addMember(
        poolId: widget.pool.id,
        candidateUid: candidateUid,
        addedBy: actorUid,
        tags: tags,
      );

      if (!mounted) return;
      _showMessage(
        'Candidato añadido al pool. Si no existía consentimiento, se ha solicitado.',
      );
    } catch (error) {
      _showMessage('No se pudo añadir el candidato: $error');
    } finally {
      if (mounted) setState(() => _isAddingMember = false);
    }
  }

  Future<void> _removeMemberFromPool(String candidateUid) async {
    try {
      await context.read<TalentPoolDetailCubit>().removeMember(
        widget.pool.id,
        candidateUid,
      );
      if (!mounted) return;
      _showMessage('Candidato eliminado del pool.');
    } catch (error) {
      _showMessage('No se pudo eliminar el candidato: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
