import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onSeeOffers});

  final VoidCallback onSeeOffers;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const accent = Color(0xFF3FA7A0);
    const border = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TALENTO + IA',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Impulsa tu talento con IA',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Una plataforma inteligente que conecta candidatos y empresas usando datos en tiempo real.',
            style: TextStyle(color: muted, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () => context.go('/CandidateLogin'),
                child: const Text('Soy candidato'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: const BorderSide(color: border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () => context.go('/CompanyLogin'),
                child: const Text('Soy empresa'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: accent),
                onPressed: onSeeOffers,
                child: const Text('Ver ofertas activas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
