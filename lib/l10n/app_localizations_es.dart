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

  @override
  String get heroTagline => 'Talento + IA';

  @override
  String get heroTitle => 'Impulsa tu talento con IA';

  @override
  String get heroDescription =>
      'Una plataforma inteligente que conecta candidatos y empresas usando datos en tiempo real.';

  @override
  String get heroCandidateCta => 'Soy candidato';

  @override
  String get heroCompanyCta => 'Soy empresa';

  @override
  String get heroOffersCta => 'Ver ofertas activas';

  @override
  String get candidateBenefitsTitle => 'Beneficios para candidatos';

  @override
  String get candidateBenefitsDescription =>
      'Recibe oportunidades diseñadas para tu perfil con una experiencia simple y directa.';

  @override
  String get candidateBenefitPersonalizedOffers =>
      'Ofertas personalizadas según tus habilidades';

  @override
  String get candidateBenefitAiRecommendations =>
      'Recomendaciones inteligentes impulsadas por IA';

  @override
  String get candidateBenefitFasterProcesses => 'Procesos más rápidos';

  @override
  String get howItWorksTitle => '¿Cómo funciona?';

  @override
  String get howItWorksDescription =>
      'Cuatro pasos claros para acelerar tus procesos de selección.';

  @override
  String get howItWorksStepRegister => 'Regístrate como empresa o candidato';

  @override
  String get howItWorksStepPublish => 'Publica ofertas o añade tu experiencia';

  @override
  String get howItWorksStepAiMatch => 'La IA conecta talento con oportunidades';

  @override
  String get howItWorksStepSchedule =>
      'Agenda entrevistas con herramientas automatizadas';

  @override
  String get ctaTitle => 'Da el salto con OPTIJOB';

  @override
  String get ctaDescription =>
      'Configura tu cuenta en minutos y empieza a recibir recomendaciones personalizadas.';

  @override
  String get ctaCompanyRegister => 'Registrar empresa';

  @override
  String get ctaCandidateRegister => 'Registrar candidato';

  @override
  String get ctaOffers => 'Ver ofertas';

  @override
  String onboardingGreeting(Object name) {
    return 'Hola, $name 👋';
  }

  @override
  String get onboardingMessage =>
      'Bienvenido a tu espacio personalizado. Antes de continuar, revisa tu perfil y completa los datos clave.';

  @override
  String get onboardingConfirmCta => 'Entendido';

  @override
  String get onboardingDefaultCandidateName => 'Candidato';

  @override
  String get onboardingDefaultCompanyName => 'Empresa';

  @override
  String get navCandidate => 'Candidato';

  @override
  String get navOffers => 'Ofertas';

  @override
  String get navCompany => 'Empresa';

  @override
  String footerCopyright(Object year) {
    return '© $year OPTIJOB. Todos los derechos reservados.';
  }

  @override
  String get appTitle => 'Optijob App';
}
