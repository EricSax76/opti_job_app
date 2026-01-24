import 'package:opti_job_app/core/platform/web_history_stub.dart'
    if (dart.library.html)
        'package:opti_job_app/core/platform/web_history_web.dart';

void pushBrowserPath(String path) => pushBrowserPathImpl(path);
