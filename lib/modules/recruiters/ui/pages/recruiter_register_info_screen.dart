import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

class RecruiterRegisterInfoScreen extends StatelessWidget {
  const RecruiterRegisterInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CoreShell(
      variant: CoreShellVariant.public,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alta de reclutadores por invitación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El acceso de reclutadores se habilita mediante una '
                    'invitación generada por el administrador de la empresa.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Si ya recibiste tu invitación y activaste tu cuenta, '
                    'puedes iniciar sesión ahora.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go('/recruiter-login'),
                    child: const Text('Ir a iniciar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
