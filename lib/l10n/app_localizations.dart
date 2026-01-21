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
