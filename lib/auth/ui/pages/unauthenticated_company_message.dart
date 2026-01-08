import 'package:flutter/material.dart';

class UnauthenticatedCompanyMessage extends StatelessWidget {
  const UnauthenticatedCompanyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceso requerido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Inicia sesión como empresa para publicar ofertas y ver tus postulantes.',
                  style: TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
