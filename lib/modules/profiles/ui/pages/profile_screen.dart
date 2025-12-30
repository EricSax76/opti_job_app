import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const border = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),
      body: const CandidateProfileView(),
    );
  }
}
