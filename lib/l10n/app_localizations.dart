import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Título de la sección de optimización con IA.
  ///
  /// In es, this message translates to:
  /// **'Optimización con IA'**
  String get aiOptimizationTitle;

  /// Descripción corta de la optimización con IA.
  ///
  /// In es, this message translates to:
  /// **'Nuestra IA analizan perfiles, automatiza entrevistas y encuentran el mejor match en segundos.'**
  String get aiOptimizationDescription;

  /// Beneficio de análisis rápido de perfiles.
  ///
  /// In es, this message translates to:
  /// **'Analiza perfiles de candidatos instantáneamente'**
  String get aiFeatureAnalyzeProfiles;

  /// Beneficio de automatización de entrevistas.
  ///
  /// In es, this message translates to:
  /// **'Automatiza la programación de entrevistas'**
  String get aiFeatureAutomateInterviews;

  /// Mensaje de error cuando falta el identificador de empresa.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los aplicantes porque falta el identificador de empresa.'**
  String get applicantsMissingCompanyId;

  /// Instrucción para expandir la tarjeta y cargar aplicantes.
  ///
  /// In es, this message translates to:
  /// **'Expande la tarjeta para cargar los aplicantes de esta oferta.'**
  String get applicantsExpandToLoad;

  /// Error genérico al cargar aplicantes.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los aplicantes.'**
  String get applicantsLoadError;

  /// Estado vacío cuando no hay aplicantes.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay postulaciones para esta oferta.'**
  String get applicantsEmpty;

  /// Etiqueta superior del hero en la landing.
  ///
  /// In es, this message translates to:
  /// **'Talento + IA'**
  String get heroTagline;

  /// Título principal del hero.
  ///
  /// In es, this message translates to:
  /// **'Impulsa tu talento con IA'**
  String get heroTitle;

  /// Descripción principal del hero.
  ///
  /// In es, this message translates to:
  /// **'Una plataforma inteligente que conecta candidatos y empresas usando datos en tiempo real.'**
  String get heroDescription;

  /// CTA para candidatos en el hero.
  ///
  /// In es, this message translates to:
  /// **'Soy candidato'**
  String get heroCandidateCta;

  /// CTA para empresas en el hero.
  ///
  /// In es, this message translates to:
  /// **'Soy empresa'**
  String get heroCompanyCta;

  /// CTA para ver ofertas activas.
  ///
  /// In es, this message translates to:
  /// **'Ver ofertas activas'**
  String get heroOffersCta;

  /// Título de la sección de beneficios para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Beneficios para candidatos'**
  String get candidateBenefitsTitle;

  /// Descripción de la sección de beneficios para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Recibe oportunidades diseñadas para tu perfil con una experiencia simple y directa.'**
  String get candidateBenefitsDescription;

  /// Beneficio de ofertas personalizadas para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Ofertas personalizadas según tus habilidades'**
  String get candidateBenefitPersonalizedOffers;

  /// Beneficio de recomendaciones por IA para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones inteligentes impulsadas por IA'**
  String get candidateBenefitAiRecommendations;

  /// Beneficio de procesos más rápidos para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Procesos más rápidos'**
  String get candidateBenefitFasterProcesses;

  /// Título de la sección de cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona?'**
  String get howItWorksTitle;

  /// Descripción de la sección de cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'Cuatro pasos claros para acelerar tus procesos de selección.'**
  String get howItWorksDescription;

  /// Paso 1 de la sección cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'Regístrate como empresa o candidato'**
  String get howItWorksStepRegister;

  /// Paso 2 de la sección cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'Publica ofertas o añade tu experiencia'**
  String get howItWorksStepPublish;

  /// Paso 3 de la sección cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'La IA conecta talento con oportunidades'**
  String get howItWorksStepAiMatch;

  /// Paso 4 de la sección cómo funciona.
  ///
  /// In es, this message translates to:
  /// **'Agenda entrevistas con herramientas automatizadas'**
  String get howItWorksStepSchedule;

  /// Título de la sección CTA.
  ///
  /// In es, this message translates to:
  /// **'Da el salto con OPTIJOB'**
  String get ctaTitle;

  /// Descripción de la sección CTA.
  ///
  /// In es, this message translates to:
  /// **'Configura tu cuenta en minutos y empieza a recibir recomendaciones personalizadas.'**
  String get ctaDescription;

  /// CTA para registrar empresa.
  ///
  /// In es, this message translates to:
  /// **'Registrar empresa'**
  String get ctaCompanyRegister;

  /// CTA para registrar candidato.
  ///
  /// In es, this message translates to:
  /// **'Registrar candidato'**
  String get ctaCandidateRegister;

  /// CTA para ver ofertas.
  ///
  /// In es, this message translates to:
  /// **'Ver ofertas'**
  String get ctaOffers;

  /// Saludo del onboarding con nombre.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name} 👋'**
  String onboardingGreeting(Object name);

  /// Mensaje principal del onboarding.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a tu espacio personalizado. Antes de continuar, revisa tu perfil y completa los datos clave.'**
  String get onboardingMessage;

  /// CTA de confirmación del onboarding.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get onboardingConfirmCta;

  /// Nombre por defecto para candidatos en onboarding.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get onboardingDefaultCandidateName;

  /// Nombre por defecto para empresas en onboarding.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get onboardingDefaultCompanyName;

  /// Etiqueta de progreso de pasos en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingCandidateStepProgressLabel(Object current, Object total);

  /// CTA para volver al paso anterior en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get onboardingCandidateBackCta;

  /// CTA para avanzar en pasos introductorios de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingCandidateNextCta;

  /// CTA para continuar en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingCandidateContinueCta;

  /// CTA para omitir temporalmente una sección opcional de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Saltar por ahora'**
  String get onboardingCandidateSkipForNowCta;

  /// CTA para finalizar onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Finalizar onboarding'**
  String get onboardingCandidateFinishCta;

  /// Título del primer paso de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido, {name}'**
  String onboardingCandidateWelcomeTitle(Object name);

  /// Mensaje del primer paso de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Te mostramos la app en menos de 2 minutos y dejamos tu perfil listo para empezar con buen matching.'**
  String get onboardingCandidateWelcomeMessage;

  /// Titular del primer paso de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Una búsqueda de empleo guiada por datos'**
  String get onboardingCandidateWelcomeHeadline;

  /// Descripción del primer paso de onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Tu panel se adapta a tus objetivos para priorizar vacantes relevantes desde el primer día.'**
  String get onboardingCandidateWelcomeDescription;

  /// Primer highlight del paso de bienvenida en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Ofertas priorizadas según tu perfil y actividad.'**
  String get onboardingCandidateWelcomeHighlightPrioritizedOffers;

  /// Segundo highlight del paso de bienvenida en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones con señales reales de compatibilidad.'**
  String get onboardingCandidateWelcomeHighlightCompatibilitySignals;

  /// Tercer highlight del paso de bienvenida en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Proceso corto, sin formularios largos al inicio.'**
  String get onboardingCandidateWelcomeHighlightShortProcess;

  /// Título del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Matches más relevantes'**
  String get onboardingCandidateSmartMatchesTitle;

  /// Mensaje del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Cuanto mejor entendemos tus prioridades laborales, mejores serán las recomendaciones que recibes.'**
  String get onboardingCandidateSmartMatchesMessage;

  /// Titular del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Menos ruido, más oportunidades útiles'**
  String get onboardingCandidateSmartMatchesHeadline;

  /// Descripción del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'OptiJob combina filtros, contexto de mercado y señales de experiencia para ordenar ofertas.'**
  String get onboardingCandidateSmartMatchesDescription;

  /// Primer highlight del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Ajuste por modalidad, ubicación y nivel de experiencia.'**
  String get onboardingCandidateSmartMatchesHighlightFilters;

  /// Segundo highlight del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Ofertas similares agrupadas para decidir más rápido.'**
  String get onboardingCandidateSmartMatchesHighlightGroupedOffers;

  /// Tercer highlight del paso de matches en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Menos tiempo filtrando, más tiempo aplicando.'**
  String get onboardingCandidateSmartMatchesHighlightLessFiltering;

  /// Título del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Tú controlas tu ritmo'**
  String get onboardingCandidateControlTitle;

  /// Mensaje del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Solo pedimos datos esenciales ahora. El resto lo puedes completar después desde tu perfil.'**
  String get onboardingCandidateControlMessage;

  /// Titular del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Onboarding no invasivo'**
  String get onboardingCandidateControlHeadline;

  /// Descripción del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Empezamos con lo mínimo útil para activar tu cuenta con calidad de matching.'**
  String get onboardingCandidateControlDescription;

  /// Primer highlight del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Preguntas de estilo de trabajo opcionales.'**
  String get onboardingCandidateControlHighlightOptionalQuestions;

  /// Segundo highlight del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Puedes saltar secciones y volver más tarde.'**
  String get onboardingCandidateControlHighlightSkipAndReturn;

  /// Tercer highlight del paso de control en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Tus preferencias te ayudan a encontrar mejor encaje cultural.'**
  String get onboardingCandidateControlHighlightCulturalFit;

  /// Título del paso opcional de estilo de trabajo en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Estilo de trabajo (opcional)'**
  String get onboardingCandidateWorkStyleTitle;

  /// Mensaje del paso opcional de estilo de trabajo en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Estas preguntas son breves y no invasivas. Nos ayudan a recomendar equipos y dinámicas compatibles.'**
  String get onboardingCandidateWorkStyleMessage;

  /// Título del paso de datos básicos en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Datos mínimos para arrancar'**
  String get onboardingCandidateProfileBasicsTitle;

  /// Mensaje del paso de datos básicos en onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Con esta información configuramos tus primeras sugerencias. Luego podrás afinar todo desde ajustes.'**
  String get onboardingCandidateProfileBasicsMessage;

  /// Mensaje de validación cuando faltan datos mínimos para finalizar onboarding de candidato.
  ///
  /// In es, this message translates to:
  /// **'Completa rol objetivo, modalidad, ubicación y seniority para finalizar.'**
  String get onboardingCandidateValidationMinimumProfileData;

  /// Etiqueta de navegación para candidatos.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get navCandidate;

  /// Etiqueta de navegación para ofertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas'**
  String get navOffers;

  /// Etiqueta de navegación para empresas.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get navCompany;

  /// Texto del footer con el año actual.
  ///
  /// In es, this message translates to:
  /// **'© {year} OPTIJOB. Todos los derechos reservados.'**
  String footerCopyright(Object year);

  /// Título de la aplicación.
  ///
  /// In es, this message translates to:
  /// **'Optijob App'**
  String get appTitle;

  /// Badge del hero en la landing.
  ///
  /// In es, this message translates to:
  /// **'Plataforma de talento con IA'**
  String get heroBadge;

  /// CTA para recruiters en el hero.
  ///
  /// In es, this message translates to:
  /// **'Soy recruiter'**
  String get heroRecruiterCta;

  /// Nav link inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// Nav link candidatos.
  ///
  /// In es, this message translates to:
  /// **'Candidatos'**
  String get navCandidates;

  /// Nav link empresas.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get navCompanies;

  /// Nav link recruiters.
  ///
  /// In es, this message translates to:
  /// **'Recruiters'**
  String get navRecruiters;

  /// Nav link funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidades'**
  String get navFeatures;

  /// CTA login en nav.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get navLogin;

  /// Título sección recruiter benefits.
  ///
  /// In es, this message translates to:
  /// **'Para recruiters'**
  String get recruiterBenefitsTitle;

  /// Descripción sección recruiter benefits.
  ///
  /// In es, this message translates to:
  /// **'Gestiona talento de múltiples empresas con herramientas profesionales de selección.'**
  String get recruiterBenefitsDescription;

  /// Beneficio talent pool.
  ///
  /// In es, this message translates to:
  /// **'Talent pool centralizado con búsqueda avanzada'**
  String get recruiterBenefitTalentPool;

  /// Beneficio ATS.
  ///
  /// In es, this message translates to:
  /// **'Pipeline ATS visual con etapas personalizables'**
  String get recruiterBenefitAts;

  /// Beneficio multi-empresa.
  ///
  /// In es, this message translates to:
  /// **'Gestión multi-empresa desde un solo panel'**
  String get recruiterBenefitMultiCompany;

  /// Beneficio RBAC.
  ///
  /// In es, this message translates to:
  /// **'Control de acceso por roles para equipos'**
  String get recruiterBenefitRbac;

  /// Beneficio knockout.
  ///
  /// In es, this message translates to:
  /// **'Preguntas knockout para filtrado automático'**
  String get recruiterBenefitKnockout;

  /// Beneficio evaluaciones.
  ///
  /// In es, this message translates to:
  /// **'Scorecards de evaluación estandarizadas'**
  String get recruiterBenefitEvaluations;

  /// Título sección company benefits.
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get companyBenefitsTitle;

  /// Descripción sección company benefits.
  ///
  /// In es, this message translates to:
  /// **'Publica ofertas, gestiona candidatos y cumple la normativa desde una sola plataforma.'**
  String get companyBenefitsDescription;

  /// Beneficio publicar ofertas.
  ///
  /// In es, this message translates to:
  /// **'Publica y gestiona ofertas de empleo fácilmente'**
  String get companyBenefitPublishOffers;

  /// Beneficio gestión candidatos.
  ///
  /// In es, this message translates to:
  /// **'Gestión centralizada de candidaturas'**
  String get companyBenefitApplicantManagement;

  /// Beneficio analytics.
  ///
  /// In es, this message translates to:
  /// **'Dashboards de analítica y rendimiento'**
  String get companyBenefitAnalytics;

  /// Beneficio compliance.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento GDPR y normativa laboral integrado'**
  String get companyBenefitCompliance;

  /// Beneficio IA ofertas.
  ///
  /// In es, this message translates to:
  /// **'Generación de ofertas asistida por IA'**
  String get companyBenefitAiJobOffers;

  /// Beneficio entrevistas.
  ///
  /// In es, this message translates to:
  /// **'Programación y gestión de entrevistas integrada'**
  String get companyBenefitInterviews;

  /// Título sección trust.
  ///
  /// In es, this message translates to:
  /// **'Confianza y cumplimiento normativo'**
  String get trustSectionTitle;

  /// Descripción sección trust.
  ///
  /// In es, this message translates to:
  /// **'Tu información protegida bajo los más altos estándares de seguridad y privacidad.'**
  String get trustSectionDescription;

  /// Item GDPR.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento total del Reglamento General de Protección de Datos (GDPR)'**
  String get trustGdpr;

  /// Item consent.
  ///
  /// In es, this message translates to:
  /// **'Gestión de consentimientos explícita y auditable'**
  String get trustConsent;

  /// Item data privacy.
  ///
  /// In es, this message translates to:
  /// **'Portal de privacidad para candidatos con control de datos'**
  String get trustDataPrivacy;

  /// Item audit trail.
  ///
  /// In es, this message translates to:
  /// **'Trazabilidad completa con audit trail de todas las acciones'**
  String get trustAuditTrail;

  /// Item AI transparency.
  ///
  /// In es, this message translates to:
  /// **'Transparencia en decisiones de IA con logs explicables'**
  String get trustAiTransparency;

  /// Título sección stats.
  ///
  /// In es, this message translates to:
  /// **'OPTIJOB en cifras'**
  String get statsTitle;

  /// Label stat empresas.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get statsCompaniesLabel;

  /// Label stat candidatos.
  ///
  /// In es, this message translates to:
  /// **'Candidatos'**
  String get statsCandidatesLabel;

  /// Label stat ofertas.
  ///
  /// In es, this message translates to:
  /// **'Ofertas publicadas'**
  String get statsOffersLabel;

  /// Label stat entrevistas.
  ///
  /// In es, this message translates to:
  /// **'Entrevistas realizadas'**
  String get statsInterviewsLabel;

  /// Título sección partners.
  ///
  /// In es, this message translates to:
  /// **'Confían en nosotros'**
  String get partnersTitle;

  /// Título columna producto footer.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get footerProductTitle;

  /// Link funcionalidades footer.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidades'**
  String get footerFeatures;

  /// Link empresas footer.
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get footerForCompanies;

  /// Link recruiters footer.
  ///
  /// In es, this message translates to:
  /// **'Para recruiters'**
  String get footerForRecruiters;

  /// Título columna legal footer.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get footerLegalTitle;

  /// Link privacidad footer.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get footerPrivacy;

  /// Link términos footer.
  ///
  /// In es, this message translates to:
  /// **'Términos de servicio'**
  String get footerTerms;

  /// Link cookies footer.
  ///
  /// In es, this message translates to:
  /// **'Política de cookies'**
  String get footerCookies;

  /// Título columna empresa footer.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get footerCompanyTitle;

  /// Link about footer.
  ///
  /// In es, this message translates to:
  /// **'Sobre nosotros'**
  String get footerAbout;

  /// Link soporte footer.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get footerSupport;

  /// Feature cover letters.
  ///
  /// In es, this message translates to:
  /// **'Generación automática de cartas de presentación'**
  String get aiFeatureCoverLetters;

  /// Feature video CV.
  ///
  /// In es, this message translates to:
  /// **'Video currículum con grabación integrada'**
  String get aiFeatureVideoCv;

  /// Feature AI job offers.
  ///
  /// In es, this message translates to:
  /// **'Creación de ofertas de empleo asistida por IA'**
  String get aiFeatureJobOfferGeneration;

  /// Feature smart matching.
  ///
  /// In es, this message translates to:
  /// **'Matching inteligente entre talento y oportunidades'**
  String get aiFeatureSmartMatching;

  /// Título página empresas.
  ///
  /// In es, this message translates to:
  /// **'La plataforma que tu empresa necesita'**
  String get paraEmpresasTitle;

  /// Subtítulo página empresas.
  ///
  /// In es, this message translates to:
  /// **'Publica ofertas, gestiona candidatos y cumple la normativa desde un solo lugar.'**
  String get paraEmpresasSubtitle;

  /// Título sección ofertas empresa.
  ///
  /// In es, this message translates to:
  /// **'Publicación de ofertas'**
  String get paraEmpresasOffersTitle;

  /// Descripción sección ofertas empresa.
  ///
  /// In es, this message translates to:
  /// **'Crea y publica ofertas de empleo con asistencia de IA. Define requisitos, salario y modalidad en minutos.'**
  String get paraEmpresasOffersDesc;

  /// Título sección candidatos empresa.
  ///
  /// In es, this message translates to:
  /// **'Gestión de candidatos'**
  String get paraEmpresasApplicantsTitle;

  /// Descripción sección candidatos empresa.
  ///
  /// In es, this message translates to:
  /// **'Visualiza, filtra y gestiona todas las candidaturas desde un panel centralizado con pipeline ATS.'**
  String get paraEmpresasApplicantsDesc;

  /// Título sección analytics empresa.
  ///
  /// In es, this message translates to:
  /// **'Analítica y métricas'**
  String get paraEmpresasAnalyticsTitle;

  /// Descripción sección analytics empresa.
  ///
  /// In es, this message translates to:
  /// **'Dashboards con métricas de rendimiento, tiempo de contratación y efectividad de tus procesos.'**
  String get paraEmpresasAnalyticsDesc;

  /// Título sección compliance empresa.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento normativo'**
  String get paraEmpresasComplianceTitle;

  /// Descripción sección compliance empresa.
  ///
  /// In es, this message translates to:
  /// **'GDPR, gestión de consentimientos y portal de privacidad integrados de serie.'**
  String get paraEmpresasComplianceDesc;

  /// Título sección entrevistas empresa.
  ///
  /// In es, this message translates to:
  /// **'Entrevistas integradas'**
  String get paraEmpresasInterviewsTitle;

  /// Descripción sección entrevistas empresa.
  ///
  /// In es, this message translates to:
  /// **'Programa, gestiona y realiza entrevistas con chat integrado y herramientas de evaluación.'**
  String get paraEmpresasInterviewsDesc;

  /// CTA página empresas.
  ///
  /// In es, this message translates to:
  /// **'Registra tu empresa'**
  String get paraEmpresasCta;

  /// Título página recruiters.
  ///
  /// In es, this message translates to:
  /// **'Herramientas profesionales de selección'**
  String get paraRecruitersTitle;

  /// Subtítulo página recruiters.
  ///
  /// In es, this message translates to:
  /// **'Gestiona talento de múltiples empresas con un ecosistema completo de recruiting.'**
  String get paraRecruitersSubtitle;

  /// Título sección talent pool recruiter.
  ///
  /// In es, this message translates to:
  /// **'Talent Pool'**
  String get paraRecruitersTalentPoolTitle;

  /// Descripción sección talent pool recruiter.
  ///
  /// In es, this message translates to:
  /// **'Base de datos centralizada de candidatos con búsqueda avanzada, etiquetas y segmentación.'**
  String get paraRecruitersTalentPoolDesc;

  /// Título sección ATS recruiter.
  ///
  /// In es, this message translates to:
  /// **'Pipeline ATS'**
  String get paraRecruitersAtsTitle;

  /// Descripción sección ATS recruiter.
  ///
  /// In es, this message translates to:
  /// **'Pipeline visual de selección con etapas configurables, preguntas knockout y filtrado automático.'**
  String get paraRecruitersAtsDesc;

  /// Título sección RBAC recruiter.
  ///
  /// In es, this message translates to:
  /// **'Gestión de equipos'**
  String get paraRecruitersRbacTitle;

  /// Descripción sección RBAC recruiter.
  ///
  /// In es, this message translates to:
  /// **'Control de acceso por roles, permisos granulares y colaboración entre recruiters.'**
  String get paraRecruitersRbacDesc;

  /// Título sección evaluaciones recruiter.
  ///
  /// In es, this message translates to:
  /// **'Evaluaciones'**
  String get paraRecruitersEvaluationsTitle;

  /// Descripción sección evaluaciones recruiter.
  ///
  /// In es, this message translates to:
  /// **'Scorecards estandarizados para evaluaciones objetivas y comparables entre candidatos.'**
  String get paraRecruitersEvaluationsDesc;

  /// Título sección multi-empresa recruiter.
  ///
  /// In es, this message translates to:
  /// **'Multi-empresa'**
  String get paraRecruitersMultiCompanyTitle;

  /// Descripción sección multi-empresa recruiter.
  ///
  /// In es, this message translates to:
  /// **'Gestiona procesos de selección de múltiples empresas desde un único panel de control.'**
  String get paraRecruitersMultiCompanyDesc;

  /// CTA página recruiters.
  ///
  /// In es, this message translates to:
  /// **'Accede como recruiter'**
  String get paraRecruitersCta;

  /// Título página funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que necesitas en una plataforma'**
  String get funcionalidadesTitle;

  /// Subtítulo página funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Descubre todas las herramientas que OPTIJOB pone a tu disposición.'**
  String get funcionalidadesSubtitle;

  /// Categoría candidatos en funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Para candidatos'**
  String get funcCategoryCandidates;

  /// Categoría empresas en funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get funcCategoryCompanies;

  /// Categoría recruiters en funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Para recruiters'**
  String get funcCategoryRecruiters;

  /// Categoría IA en funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'IA y automatización'**
  String get funcCategoryAi;

  /// Categoría compliance en funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Compliance y seguridad'**
  String get funcCategoryCompliance;

  /// Funcionalidad búsqueda.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda inteligente de ofertas'**
  String get funcSmartSearch;

  /// Descripción búsqueda.
  ///
  /// In es, this message translates to:
  /// **'Encuentra oportunidades relevantes con filtros avanzados y recomendaciones personalizadas.'**
  String get funcSmartSearchDesc;

  /// Funcionalidad CV.
  ///
  /// In es, this message translates to:
  /// **'Gestión de currículum'**
  String get funcCvManagement;

  /// Descripción CV.
  ///
  /// In es, this message translates to:
  /// **'Crea y gestiona tu CV con secciones estructuradas y exportación profesional.'**
  String get funcCvManagementDesc;

  /// Funcionalidad tracking.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de candidaturas'**
  String get funcApplicationTracking;

  /// Descripción tracking.
  ///
  /// In es, this message translates to:
  /// **'Monitoriza el estado de tus aplicaciones en tiempo real.'**
  String get funcApplicationTrackingDesc;

  /// Funcionalidad ofertas.
  ///
  /// In es, this message translates to:
  /// **'Publicación de ofertas'**
  String get funcOfferPublishing;

  /// Descripción ofertas.
  ///
  /// In es, this message translates to:
  /// **'Crea ofertas detalladas con requisitos, salario y modalidad de trabajo.'**
  String get funcOfferPublishingDesc;

  /// Funcionalidad ATS.
  ///
  /// In es, this message translates to:
  /// **'Pipeline ATS'**
  String get funcAtsPipeline;

  /// Descripción ATS.
  ///
  /// In es, this message translates to:
  /// **'Gestiona candidatos en un pipeline visual con etapas configurables.'**
  String get funcAtsPipelineDesc;

  /// Funcionalidad equipos.
  ///
  /// In es, this message translates to:
  /// **'Gestión de equipos'**
  String get funcTeamManagement;

  /// Descripción equipos.
  ///
  /// In es, this message translates to:
  /// **'Administra roles y permisos de tu equipo de recruiting.'**
  String get funcTeamManagementDesc;

  /// Funcionalidad talent pool.
  ///
  /// In es, this message translates to:
  /// **'Talent Pool'**
  String get funcTalentPool;

  /// Descripción talent pool.
  ///
  /// In es, this message translates to:
  /// **'Base de datos centralizada de candidatos con etiquetas y segmentación.'**
  String get funcTalentPoolDesc;

  /// Funcionalidad análisis perfiles.
  ///
  /// In es, this message translates to:
  /// **'Análisis de perfiles con IA'**
  String get funcProfileAnalysis;

  /// Descripción análisis perfiles.
  ///
  /// In es, this message translates to:
  /// **'Evaluación automática de candidatos basada en competencias y experiencia.'**
  String get funcProfileAnalysisDesc;

  /// Funcionalidad entrevistas.
  ///
  /// In es, this message translates to:
  /// **'Programación de entrevistas'**
  String get funcInterviewScheduling;

  /// Descripción entrevistas.
  ///
  /// In es, this message translates to:
  /// **'Agenda y gestiona entrevistas con herramientas automatizadas y chat integrado.'**
  String get funcInterviewSchedulingDesc;

  /// Funcionalidad GDPR.
  ///
  /// In es, this message translates to:
  /// **'GDPR y protección de datos'**
  String get funcGdprCompliance;

  /// Descripción GDPR.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento normativo integrado con gestión de consentimientos y auditoría.'**
  String get funcGdprComplianceDesc;

  /// CTA ver funcionalidades.
  ///
  /// In es, this message translates to:
  /// **'Ver todas las funcionalidades'**
  String get funcSeeAllFeatures;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
