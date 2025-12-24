import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const accent = Color(0xFF3FA7A0);
    const border = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Da el salto con OPTIJOB',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Configura tu cuenta en minutos y empieza a recibir recomendaciones personalizadas.',
            style: TextStyle(color: muted, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go('/companyregister'),
                child: const Text('Registrar empresa'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: const BorderSide(color: border),
                ),
                onPressed: () => context.go('/candidateregister'),
                child: const Text('Registrar candidato'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: accent),
                onPressed: () => context.go('/job-offer'),
                child: const Text('Ver ofertas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
