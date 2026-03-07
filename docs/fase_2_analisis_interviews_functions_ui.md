# Fase 2: Analisis de Integracion (carpeta interviews)

## Objetivo
Cerrar evidencia tecnica de conexion backend->UI para la carpeta `interviews`.

## Inventario backend (carpeta interviews)
- `startInterview` en `functions/src/callable/interviews/startInterview.ts:69`
- `sendInterviewMessage` en `functions/src/callable/interviews/sendInterviewMessage.ts:45`
- `proposeInterviewSlot` en `functions/src/callable/interviews/proposeInterviewSlot.ts:17`
- `respondInterviewSlot` en `functions/src/callable/interviews/respondInterviewSlot.ts:17`
- `markInterviewSeen` en `functions/src/callable/interviews/markInterviewSeen.ts:16`
- `cancelInterview` en `functions/src/callable/interviews/cancelInterview.ts:17`
- `completeInterview` en `functions/src/callable/interviews/completeInterview.ts:17`

Exports relacionados en `functions/src/index.ts`:
- `functions/src/index.ts:68` (`startInterview`)
- `functions/src/index.ts:69` (`sendInterviewMessage`)
- `functions/src/index.ts:70` (`proposeInterviewSlot`)
- `functions/src/index.ts:71` (`respondInterviewSlot`)
- `functions/src/index.ts:72` (`markInterviewSeen`)
- `functions/src/index.ts:73` (`cancelInterview`)
- `functions/src/index.ts:74` (`completeInterview`)

## Evidencia frontend por callable
1. `startInterview`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:64`
- Flujo UI enlazado:
  - `lib/modules/applicants/ui/widgets/offer_applicants_section.dart:117`
  - `lib/modules/applicants/logic/offer_applicants_section_logic.dart:49`
  - `lib/modules/applicants/cubits/applicant_interaction_cubit.dart:16`
  - `lib/modules/companies/ui/widgets/offers/company_offers_tab.dart:17`

2. `sendInterviewMessage`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:86`
- Flujo UI enlazado:
  - `lib/modules/interviews/ui/widgets/chat/interview_message_input_area.dart:66`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:17`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:22`
  - `lib/modules/interviews/ui/widgets/chat/interview_chat_container.dart:69`

3. `proposeInterviewSlot`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:100`
- Flujo UI enlazado:
  - `lib/modules/interviews/ui/widgets/chat/interview_message_input_area.dart:60`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:26`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:34`
  - `lib/modules/interviews/ui/widgets/chat/interview_chat_container.dart:70`

4. `respondInterviewSlot`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:113`
- Flujo UI enlazado:
  - `lib/modules/interviews/ui/widgets/chat/interview_message_bubble.dart:102`
  - `lib/modules/interviews/ui/widgets/chat/interview_message_bubble.dart:114`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:40`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:41`

5. `markInterviewSeen`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:122`
- Flujo UI enlazado:
  - `lib/core/router/routes/public_routes.dart:106`
  - `lib/core/router/routes/public_routes.dart:116`
  - `lib/modules/interviews/cubits/interview_session_cubit.dart:71`
  - `lib/modules/interviews/cubits/interview_session_cubit.dart:73`

6. `cancelInterview`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:128`
- Flujo UI enlazado:
  - `lib/modules/interviews/cubits/interview_session_cubit.dart:121`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:65`
  - `lib/modules/interviews/ui/widgets/chat/interview_chat_container.dart:155`
  - `lib/modules/interviews/ui/widgets/interview_list_tile.dart:164`
- Visibilidad por rol:
  - visible solo para participantes de la entrevista y cuando el estado no es `cancelled/completed`.
- Clasificacion: `direct_ui`.

7. `completeInterview`
- Invocacion callable en:
  - `lib/modules/interviews/repositories/firebase_interview_repository.dart:136`
- Flujo UI enlazado:
  - `lib/modules/interviews/cubits/interview_session_cubit.dart:127`
  - `lib/modules/interviews/ui/controllers/interview_chat_actions_controller.dart:54`
  - `lib/modules/interviews/ui/widgets/chat/interview_chat_container.dart:152`
  - `lib/modules/interviews/ui/widgets/interview_list_tile.dart:152`
- Visibilidad por rol:
  - visible solo para `companyUid` propietario de la entrevista y cuando el estado no es `cancelled/completed`.
- Clasificacion: `direct_ui`.

## Evidencia de dataflow
- `startInterview` crea `interviews/{applicationId}` y actualiza `applications.status = "interview"`:
  - `functions/src/callable/interviews/startInterview.ts:167`
  - `functions/src/callable/interviews/startInterview.ts:210`
- `sendInterviewMessage` agrega mensaje y actualiza `lastMessage` + `unreadCounts`:
  - `functions/src/callable/interviews/sendInterviewMessage.ts:114`
  - `functions/src/callable/interviews/sendInterviewMessage.ts:126`
- `proposeInterviewSlot` agrega mensaje `proposal` con metadata (`proposalId`, `proposedAt`, `timeZone`):
  - `functions/src/callable/interviews/proposeInterviewSlot.ts:58`
  - `functions/src/callable/interviews/proposeInterviewSlot.ts:65`
- `respondInterviewSlot` acepta/rechaza propuesta y en aceptacion fija `status: scheduled` y crea `calendarEvents`:
  - `functions/src/callable/interviews/respondInterviewSlot.ts:81`
  - `functions/src/callable/interviews/respondInterviewSlot.ts:112`
- `markInterviewSeen` resetea `unreadCounts.{uid}`:
  - `functions/src/callable/interviews/markInterviewSeen.ts:55`
- `cancelInterview` actualiza `status=cancelled` y escribe mensaje `system`:
  - `functions/src/callable/interviews/cancelInterview.ts:56`
  - `functions/src/callable/interviews/cancelInterview.ts:63`
- `completeInterview` actualiza `status=completed` y escribe mensaje `system`:
  - `functions/src/callable/interviews/completeInterview.ts:59`
  - `functions/src/callable/interviews/completeInterview.ts:66`

## Hallazgos tecnicos
- `cancelInterview` y `completeInterview` quedaron cableadas en `chat` y `listado` con menú de acciones y gating por rol en frontend.
- `startMeeting` (chat) se ejecuta por escritura directa a Firestore desde cliente (`firebase_interview_repository.dart:148`), sin callable backend equivalente.

## Clasificacion cerrada de carpeta interviews
1. `startInterview`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

2. `sendInterviewMessage`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

3. `proposeInterviewSlot`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

4. `respondInterviewSlot`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

5. `markInterviewSeen`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

6. `cancelInterview`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

7. `completeInterview`
- Estado: `reviewed`
- Tipo de conexion: `direct_ui`
- Riesgo: `low`
- Recomendacion: `keep`

## Validacion E2E
- Suite nueva: `functions/e2e/p3_interviews_actions_callables.test.js`
- Cobertura:
  - participante puede cancelar entrevista activa,
  - company owner puede completar entrevista,
  - candidato no puede completar (permiso denegado).

## Cambios aplicados
- Matriz actualizada en:
  - `docs/fase_1_matriz_trazabilidad_functions_ui.csv`

## Siguiente carpeta recomendada
Continuar con `compliance`.
