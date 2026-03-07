import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/talent_pool/cubits/talent_pool_detail_cubit.dart';
import 'package:opti_job_app/modules/talent_pool/cubits/talent_pool_list_cubit.dart';
import 'package:opti_job_app/modules/talent_pool/models/talent_pool.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';
import 'package:opti_job_app/modules/talent_pool/ui/pages/talent_pool_detail_screen.dart';

class TalentPoolListScreen extends StatefulWidget {
  const TalentPoolListScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<TalentPoolListScreen> createState() => _TalentPoolListScreenState();
}

class _TalentPoolListScreenState extends State<TalentPoolListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TalentPoolListCubit>().loadPools(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talent Pools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePoolDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<TalentPoolListCubit, TalentPoolListState>(
        builder: (context, state) {
          if (state.status == TalentPoolListStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TalentPoolListStatus.failure) {
            return const StateMessage(
              title: 'Error cargando pools',
              message: 'No se pudieron recuperar los talent pools.',
            );
          }
          if (state.pools.isEmpty) {
            return const StateMessage(
              title: 'Sin pools',
              message: 'Aún no se ha creado ningún talent pool.',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(uiSpacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Talent Pools',
                  subtitle: 'Organiza candidatos por objetivo y prioridad.',
                  titleFontSize: 24,
                ),
                const SizedBox(height: uiSpacing16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: uiSpacing16,
                          mainAxisSpacing: uiSpacing16,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: state.pools.length,
                    itemBuilder: (context, index) {
                      final pool = state.pools[index];
                      return _PoolCard(pool: pool);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreatePoolDialog(BuildContext context) {
    final creatorUid = context.read<FirebaseAuth>().currentUser?.uid ?? '';
    final listCubit = context.read<TalentPoolListCubit>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Pool Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                listCubit.createPool(
                  TalentPool(
                    id: '',
                    companyId: widget.companyId,
                    name: nameController.text,
                    description: descController.text,
                    createdBy: creatorUid,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.pool});

  final TalentPool pool;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (_) => TalentPoolDetailCubit(
                repository: context.read<TalentPoolRepository>(),
              ),
              child: TalentPoolDetailScreen(pool: pool),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(uiSpacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pool.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: uiSpacing4),
            Text(
              pool.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            InfoPill(
              icon: Icons.people_outline,
              label: '${pool.memberCount} members',
            ),
          ],
        ),
      ),
    );
  }
}
