# Fase 6.1: Inventario y frontera de shell

Fecha de auditoria: 2026-02-17  
Estado: completada

## Objetivo
Definir exactamente donde aplica el shell comun y detectar desviaciones actuales (`Scaffold`/`appBar`) en rutas funcionales.

## Frontera de shell comun (aplica/no aplica)
Aplica:
1. Pantallas enrutable por `GoRouter` (paginas funcionales).
2. Pantallas full page abiertas por `Navigator.push` dentro de flujos funcionales.
3. Dashboards y sus superficies de navegacion principal (app bar, drawer/sidebar, bottom nav).

No aplica:
1. Overlays transitorios (`showDialog`, `showModalBottomSheet`, `SnackBar`).
2. Widgets leaf/presentacionales sin responsabilidad de layout de pagina.
3. Flujos declarados como excepcion en allowlist.

## Evidencia de auditoria (comandos)
1. `rg -n "Scaffold\\(" lib --glob '*screen.dart' --glob '*page.dart' --glob '*view.dart'`
2. `rg -n "appBar:\\s*" lib --glob '*screen.dart' --glob '*page.dart' --glob '*view.dart'`
3. `rg -n "ShellRoute|GoRoute\\(|path:\\s*'" lib/core/router/app_router.dart`

## Inventario versionado por ruta (GoRouter)
| Ruta | Route name | Pantalla raiz | Archivo | Estado |
| --- | --- | --- | --- | --- |
| `/` | `landing` | `LandingScreen` | `lib/home/pages/landing_screen.dart` | `migrar` |
| `/job-offer` | `job-offers` | `JobOfferListScreen` | `lib/modules/job_offers/ui/pages/job_offer_list_screen.dart` | `migrar` |
| `/job-offer/:id` | `job-offer-detail` | `JobOfferDetailScreen` | `lib/modules/job_offers/ui/pages/job_offer_detail_screen.dart` | `migrar` |
| `/CandidateDashboard` | `candidate-dashboard-legacy` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/dashboard` | `candidate-dashboard` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/applications` | `candidate-applications` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/interviews` | `candidate-interviews` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/cv` | `candidate-cv` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/cover-letter` | `candidate-cover-letter` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/candidate/:uid/video-cv` | `candidate-video-cv` | `CandidateDashboardScreen` | `lib/modules/candidates/ui/pages/candidate_dashboard_screen.dart` | `migrar` |
| `/DashboardCompany` | `company-dashboard` | `CompanyDashboardScreen` | `lib/modules/companies/ui/pages/company_dashboard_screen.dart` | `migrar` |
| `/company/profile` | `company-profile` | `CompanyProfileScreen` | `lib/modules/companies/ui/pages/company_profile_screen.dart` | `migrar` |
| `/company/offers/:offerId/applicants/:uid/cv` | `company-applicant-cv` | `ApplicantCurriculumScreen` | `lib/modules/applicants/ui/pages/applicant_curriculum_screen.dart` | `migrar` |
| `/CandidateLogin` | `candidate-login` | `CandidateLoginScreen` | `lib/auth/ui/pages/candidate_login_screen.dart` | `migrar` |
| `/candidateregister` | `candidate-register` | `CandidateRegisterScreen` | `lib/auth/ui/pages/candidate_register_screen.dart` | `migrar` |
| `/CompanyLogin` | `company-login` | `CompanyLoginScreen` | `lib/auth/ui/pages/company_login_screen.dart` | `migrar` |
| `/companyregister` | `company-register` | `CompanyRegisterScreen` | `lib/auth/ui/pages/company_register_screen.dart` | `migrar` |
| `/onboarding` | `onboarding` | `OnboardingScreen` | `lib/home/pages/onboarding_screen.dart` | `migrar` |
| `/interviews/:id` | `interview-chat` | `InterviewChatPage` | `lib/modules/interviews/ui/pages/interview_chat_page.dart` | `excepcion` |

## Inventario de superficies funcionales fuera de GoRouter
| Superficie | Entrada | Archivo | Estado |
| --- | --- | --- | --- |
| Perfil candidato (push interno desde dashboard) | `Navigator.push(MaterialPageRoute)` | `lib/modules/profiles/ui/pages/profile_screen.dart` | `migrar` |
| Reproductor de video (push interno) | `Navigator.push(MaterialPageRoute)` | `lib/features/video_curriculum/view/video_playback_screen.dart` | `excepcion` |

## Desviaciones detectadas (deuda de shell)
| Desviacion | Archivo | Estado |
| --- | --- | --- |
| `Scaffold` de dashboard no estandarizado en core | `lib/modules/candidates/ui/widgets/candidate_dashboard_scaffold.dart` | `migrar` |
| `Scaffold` anidado en tab de entrevistas (candidate) | `lib/modules/candidates/ui/widgets/interviews_view.dart` | `migrar` |
| `Scaffold` anidado en tab de entrevistas (company) | `lib/modules/companies/ui/widgets/company_interviews_tab.dart` | `migrar` |
| `Scaffold` en pantalla de carta dentro de dashboard | `lib/features/cover_letter/view/cover_letter_screen.dart` | `migrar` |

## Allowlist inicial de excepciones (Fase 6.1)
| Id | Ruta/flujo | Archivo principal | Motivo | Owner | Revision |
| --- | --- | --- | --- | --- | --- |
| `shell-ex-001` | Chat de entrevista (`/interviews/:id`) | `lib/modules/interviews/ui/widgets/chat/interview_chat_view.dart` | Flujo conversacional inmersivo; requiere evaluacion de variant `immersive` antes de migrar. | `frontend-core` | `2026-08-17` |
| `shell-ex-002` | Playback de video curriculum (push interno) | `lib/features/video_curriculum/view/video_playback_screen.dart` | Flujo multimedia inmersivo/fullscreen con controles dedicados. | `frontend-core` | `2026-08-17` |

Nota:
- Desde Fase 6.5, la fuente de verdad de excepciones activas y revisiones es `docs/fase_6_5_registro_excepciones_shell_core.md`.

## Resumen de clasificacion
1. Rutas `GoRouter` auditadas: 19.
2. Superficies funcionales adicionales (`Navigator.push`): 2.
3. Total inventariado: 21.
4. Estado `migrar`: 19.
5. Estado `ok`: 0.
6. Estado `excepcion`: 2.

## Criterio de cierre de 6.1 cumplido
1. Auditoria de `Scaffold`/`appBar` ejecutada.
2. Clasificacion por pagina publicada (`migrar`/`ok`/`excepcion`).
3. Allowlist inicial de excepciones publicada y versionada.
