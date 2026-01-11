import 'dart:io' show File;
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

part 'cover_letter_event.dart';
part 'cover_letter_state.dart';

typedef CurriculumProvider = Curriculum? Function();
typedef CandidateUidProvider = String? Function();

class CoverLetterBloc extends Bloc<CoverLetterEvent, CoverLetterState> {
  CoverLetterBloc({
    required AiRepository aiRepository,
    required CurriculumProvider curriculumProvider,
    required CandidateUidProvider candidateUidProvider,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _aiRepository = aiRepository,
       _curriculumProvider = curriculumProvider,
       _candidateUidProvider = candidateUidProvider,
       _firestore = firestore,
       _storage = storage,
       super(const CoverLetterState()) {
    on<LoadCoverLetterRequested>(_onLoadCoverLetterRequested);
    on<VideoRecordingStarted>(_onVideoRecordingStarted);
    on<VideoRecordingStopped>(_onVideoRecordingStopped);
    on<RetryVideoRecording>(_onRetryVideoRecording);
    on<ImproveCoverLetterRequested>(_onImproveCoverLetterRequested);
    on<SaveCoverLetterAndVideo>(_onSaveCoverLetterAndVideo);
  }

  final AiRepository _aiRepository;
  final CurriculumProvider _curriculumProvider;
  final CandidateUidProvider _candidateUidProvider;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  Future<void> _onLoadCoverLetterRequested(
    LoadCoverLetterRequested event,
    Emitter<CoverLetterState> emit,
  ) async {
    final uid = _candidateUidProvider();
    if (uid == null) return;

    emit(state.copyWith(status: CoverLetterStatus.loading, error: () => null));
    try {
      final firestore = _firestore ?? FirebaseFirestore.instance;
      final doc = await firestore.collection('candidates').doc(uid).get();
      final data = doc.data();
      final coverLetter = data?['cover_letter'];
      final rawText = coverLetter is Map ? coverLetter['text'] : null;
      final text = rawText is String ? rawText.trim() : null;

      emit(
        state.copyWith(
          status: CoverLetterStatus.initial,
          savedCoverLetterText: (text == null || text.isEmpty) ? null : text,
          error: () => null,
        ),
      );
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message ?? 'No se pudo cargar tu carta.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }

  void _onVideoRecordingStarted(
    VideoRecordingStarted event,
    Emitter<CoverLetterState> emit,
  ) {
    if (state.attemptsLeft > 0) {
      emit(state.copyWith(status: CoverLetterStatus.recording));
    }
  }

  void _onVideoRecordingStopped(
    VideoRecordingStopped event,
    Emitter<CoverLetterState> emit,
  ) {
    emit(
      state.copyWith(
        recordedVideoPath: event.path,
        status: CoverLetterStatus.success,
        attemptsLeft: state.attemptsLeft - 1,
      ),
    );
  }

  void _onRetryVideoRecording(
    RetryVideoRecording event,
    Emitter<CoverLetterState> emit,
  ) {
    if (state.attemptsLeft > 0) {
      emit(
        state.copyWith(
          recordedVideoPath: null,
          status: CoverLetterStatus.initial,
          error: () => null,
        ),
      );
    }
  }

  Future<void> _onImproveCoverLetterRequested(
    ImproveCoverLetterRequested event,
    Emitter<CoverLetterState> emit,
  ) async {
    try {
      final curriculum = _curriculumProvider();
      if (curriculum == null) {
        emit(
          state.copyWith(
            status: CoverLetterStatus.failure,
            error: () =>
                'Completa tu CV primero para que la IA pueda generar una carta.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CoverLetterStatus.improving,
          error: () => null,
        ),
      );

      final improvedText = await _aiRepository.improveCoverLetter(
        curriculum: curriculum,
        coverLetterText: event.originalText,
        locale: event.locale,
      );
      emit(
        state.copyWith(
          status: CoverLetterStatus.success,
          improvedCoverLetter: improvedText,
          error: () => null,
        ),
      );
    } on AiConfigurationException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message,
        ),
      );
    } on AiRequestException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveCoverLetterAndVideo(
    SaveCoverLetterAndVideo event,
    Emitter<CoverLetterState> emit,
  ) async {
    final shouldRequireVideo = event.coverLetterText.trim().isEmpty;
    if (shouldRequireVideo && state.recordedVideoPath == null) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => 'Primero debes grabar un vídeo.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CoverLetterStatus.uploading));
    try {
      final coverLetterText = event.coverLetterText.trim();
      final uid = _candidateUidProvider();
      if (uid == null) {
        emit(
          state.copyWith(
            status: CoverLetterStatus.failure,
            error: () => 'Debes iniciar sesión para guardar.',
          ),
        );
        return;
      }

      if (coverLetterText.isNotEmpty) {
        final firestore = _firestore ?? FirebaseFirestore.instance;
        await firestore.collection('candidates').doc(uid).update({
          'cover_letter': {
            'text': coverLetterText,
            'updated_at': FieldValue.serverTimestamp(),
          },
          'updated_at': FieldValue.serverTimestamp(),
        });
        emit(state.copyWith(savedCoverLetterText: coverLetterText));
      }

      if (shouldRequireVideo && state.recordedVideoPath != null) {
        await _uploadVideoCurriculum(
          candidateUid: uid,
          filePath: state.recordedVideoPath!,
        );
      }

      emit(state.copyWith(status: CoverLetterStatus.success));
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => error.message ?? 'No se pudo guardar tu carta.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CoverLetterStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }

  Future<void> _uploadVideoCurriculum({
    required String candidateUid,
    required String filePath,
  }) async {
    final storage = _storage ?? FirebaseStorage.instance;
    final normalizedPath = filePath.toLowerCase();
    final contentType = normalizedPath.endsWith('.mov')
        ? 'video/quicktime'
        : 'video/mp4';
    final extension = contentType == 'video/quicktime' ? 'mov' : 'mp4';
    final storagePath =
        'candidates/$candidateUid/video_curriculum/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = storage.ref().child(storagePath);
    int sizeBytes;
    if (kIsWeb) {
      final bytes = await XFile(filePath).readAsBytes();
      if (bytes.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          message: 'El vídeo grabado está vacío.',
        );
      }
      sizeBytes = bytes.length;
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
    } else {
      final file = File(filePath);
      sizeBytes = await file.length();
      if (sizeBytes == 0) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          message: 'El vídeo grabado está vacío.',
        );
      }
      await ref.putFile(file, SettableMetadata(contentType: contentType));
    }

    final firestore = _firestore ?? FirebaseFirestore.instance;
    await firestore.collection('candidates').doc(candidateUid).update({
      'video_curriculum': {
        'storage_path': storagePath,
        'content_type': contentType,
        'size_bytes': sizeBytes,
        'updated_at': FieldValue.serverTimestamp(),
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
