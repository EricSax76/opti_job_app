import 'package:video_player/video_player.dart';

import 'package:opti_job_app/features/video_curriculum/view/video_playback_controller_stub.dart'
    if (dart.library.io) 'package:opti_job_app/features/video_curriculum/view/video_playback_controller_io.dart'
    if (dart.library.js_interop) 'package:opti_job_app/features/video_curriculum/view/video_playback_controller_web.dart';

VideoPlayerController createVideoController(Uri uri) => createController(uri);
