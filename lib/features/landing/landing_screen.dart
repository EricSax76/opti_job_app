import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/widgets/app_footer.dart';
import '../shared/widgets/app_nav_bar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _HeroSection(onSeeOffers: () => context.go('/job-offer')),
          const SizedBox(height: 48),
          const _FeatureSection(),
          const SizedBox(height: 48),
          const _CandidateBenefitsSection(),
          const SizedBox(height: 48),
          const _HowItWorksSection(),
          const SizedBox(height: 48),
          const _CallToAction(),
        ],
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onSeeOffers});

  final VoidCallback onSeeOffers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Impulsa tu talento con IA',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Una plataforma inteligente que conecta candidatos y empresas usando datos en tiempo real.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.go('/CandidateLogin'),
              child: const Text('Soy candidato'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/CompanyLogin'),
              child: const Text('Soy empresa'),
            ),
            TextButton(
              onPressed: onSeeOffers,
              child: const Text('Ver ofertas activas'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimización con IA',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Los algoritmos analizan perfiles, automatizan entrevistas y encuentran el mejor match en segundos.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        const _HighlightList(
          items: [
            'Analiza perfiles de candidatos instantáneamente',
            'Automatiza la programación de entrevistas',
            'Identifica el mejor ajuste basado en datos',
          ],
        ),
      ],
    );
  }
}

class _CandidateBenefitsSection extends StatelessWidget {
  const _CandidateBenefitsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficios para candidatos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const _HighlightList(
          items: [
            'Ofertas personalizadas según tus habilidades',
            'Recomendaciones inteligentes impulsadas por IA',
            'Procesos más rápidos y sin fricciones',
          ],
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Regístrate como empresa o candidato',
      'Publica ofertas o añade tu experiencia',
      'La IA conecta talento con oportunidades',
      'Agenda entrevistas con herramientas automatizadas',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo funciona?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.indigo),
                ),
              ),
              title: Text(steps[index]),
            );
          },
        ),
      ],
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Da el salto con OPTIJOB',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Configura tu cuenta en minutos y empieza a recibir recomendaciones personalizadas.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () => context.go('/companyregister'),
                  child: const Text('Registrar empresa'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/candidateregister'),
                  child: const Text('Registrar candidato'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightList extends StatelessWidget {
  const _HighlightList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontSize: 18, color: Colors.indigo)),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
