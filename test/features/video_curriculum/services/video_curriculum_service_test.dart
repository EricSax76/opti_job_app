import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/features/video_curriculum/services/video_curriculum_service.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

class _MockReference extends Mock implements Reference {}

class _FakeTaskSnapshot extends Fake implements TaskSnapshot {}

class _ImmediateUploadTask extends Fake implements UploadTask {
  _ImmediateUploadTask() : _snapshot = _FakeTaskSnapshot();

  final TaskSnapshot _snapshot;

  @override
  Stream<TaskSnapshot> asStream() => Stream<TaskSnapshot>.value(_snapshot);

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) async {
    return _snapshot;
  }

  @override
  Future<bool> cancel() async => true;

  @override
  Future<bool> pause() async => true;

  @override
  Future<bool> resume() async => true;

  @override
  TaskSnapshot get snapshot => _snapshot;

  @override
  Stream<TaskSnapshot> get snapshotEvents =>
      Stream<TaskSnapshot>.value(_snapshot);

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) async {
    return await onValue(_snapshot);
  }

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) async {
    return _snapshot;
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() action) async {
    await action();
    return _snapshot;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(File('/tmp/mock_file.mp4'));
    registerFallbackValue(SettableMetadata());
  });

  group('VideoCurriculumService', () {
    test('throws FirebaseException when local file is empty', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({});
      final storage = _MockFirebaseStorage();
      final rootRef = _MockReference();
      final uploadRef = _MockReference();
      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child(any())).thenReturn(uploadRef);

      final service = VideoCurriculumService(
        firestore: firestore,
        storage: storage,
      );
      final file = await _createTempFile('empty_video.mp4', const []);

      expect(
        () => service.uploadVideoCurriculum(
          candidateUid: 'candidate-1',
          filePath: file.path,
        ),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.message,
            'message',
            'El vídeo grabado está vacío.',
          ),
        ),
      );
      verifyNever(() => uploadRef.putFile(any(), any()));
    });

    test('uploads mp4 and writes video metadata to Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-1').set({});
      final storage = _MockFirebaseStorage();
      final rootRef = _MockReference();
      final uploadRef = _MockReference();
      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child(any())).thenReturn(uploadRef);
      when(
        () => uploadRef.putFile(any(), any()),
      ).thenAnswer((_) => _ImmediateUploadTask());

      final service = VideoCurriculumService(
        firestore: firestore,
        storage: storage,
      );
      final file = await _createTempFile('video_ok.mp4', const [1, 2, 3, 4]);

      await service.uploadVideoCurriculum(
        candidateUid: 'candidate-1',
        filePath: file.path,
      );

      verify(() => uploadRef.putFile(any(), any())).called(1);
      final snapshot = await firestore
          .collection('candidates')
          .doc('candidate-1')
          .get();
      final data = snapshot.data();
      expect(data, isNotNull);

      final videoData = data!['video_curriculum'] as Map<String, dynamic>?;
      expect(videoData, isNotNull);
      expect(videoData!['content_type'], 'video/mp4');
      expect(videoData['size_bytes'], 4);
      expect(
        (videoData['storage_path'] as String).startsWith(
          'candidates/candidate-1/video_curriculum/',
        ),
        isTrue,
      );
      expect((videoData['storage_path'] as String).endsWith('.mp4'), isTrue);
      expect(videoData['updated_at'], isNotNull);
      expect(data['updated_at'], isNotNull);
    });

    test('uses quicktime metadata for .mov files', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('candidate-2').set({});
      final storage = _MockFirebaseStorage();
      final rootRef = _MockReference();
      final uploadRef = _MockReference();
      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child(any())).thenReturn(uploadRef);
      when(
        () => uploadRef.putFile(any(), any()),
      ).thenAnswer((_) => _ImmediateUploadTask());

      final service = VideoCurriculumService(
        firestore: firestore,
        storage: storage,
      );
      final file = await _createTempFile('video_ok.MOV', const [9, 8, 7]);

      await service.uploadVideoCurriculum(
        candidateUid: 'candidate-2',
        filePath: file.path,
      );

      final snapshot = await firestore
          .collection('candidates')
          .doc('candidate-2')
          .get();
      final data = snapshot.data();
      expect(data, isNotNull);

      final videoData = data!['video_curriculum'] as Map<String, dynamic>?;
      expect(videoData, isNotNull);
      expect(videoData!['content_type'], 'video/quicktime');
      expect((videoData['storage_path'] as String).endsWith('.mov'), isTrue);
    });
  });
}

Future<File> _createTempFile(String name, List<int> bytes) async {
  final extensionSeparator = name.lastIndexOf('.');
  final baseName = extensionSeparator == -1
      ? name
      : name.substring(0, extensionSeparator);
  final extension = extensionSeparator == -1
      ? ''
      : name.substring(extensionSeparator);
  final file = File(
    '${Directory.systemTemp.path}/'
    '${baseName}_${DateTime.now().microsecondsSinceEpoch}$extension',
  );
  await file.writeAsBytes(bytes);
  addTearDown(() async {
    if (await file.exists()) {
      await file.delete();
    }
  });
  return file;
}
