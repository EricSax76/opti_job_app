import 'package:flutter/material.dart';

class UnauthenticatedCompanyMessage extends StatelessWidget {
  const UnauthenticatedCompanyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Inicia sesión como empresa para publicar ofertas.'),
    );
  }
}
