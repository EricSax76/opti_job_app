// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get aiOptimizationTitle => 'Optimización con IA';

  @override
  String get aiOptimizationDescription =>
      'Nuestra IA analizan perfiles, automatiza entrevistas y encuentran el mejor match en segundos.';

  @override
  String get aiFeatureAnalyzeProfiles =>
      'Analiza perfiles de candidatos instantáneamente';

  @override
  String get aiFeatureAutomateInterviews =>
      'Automatiza la programación de entrevistas';

  @override
  String get applicantsMissingCompanyId =>
      'No se pudieron cargar los aplicantes porque falta el identificador de empresa.';

  @override
  String get applicantsExpandToLoad =>
      'Expande la tarjeta para cargar los aplicantes de esta oferta.';

  @override
  String get applicantsLoadError => 'No se pudieron cargar los aplicantes.';

  @override
  String get applicantsEmpty => 'Aún no hay postulaciones para esta oferta.';
}
