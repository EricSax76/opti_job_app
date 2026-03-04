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

  @override
  void initState() {
    super.initState();
    context.read<TalentPoolDetailCubit>().subscribeToMembers(widget.pool.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pool.name)),
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
                      onRemove: () {
                        context.read<TalentPoolDetailCubit>().removeMember(
                          widget.pool.id,
                          member.candidateUid,
                        );
                      },
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
}
