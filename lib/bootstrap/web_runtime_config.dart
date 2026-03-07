import 'package:opti_job_app/bootstrap/web_runtime_config_stub.dart'
    if (dart.library.js_interop) 'package:opti_job_app/bootstrap/web_runtime_config_web.dart';

String? readWebRuntimeConfigValue(String key) =>
    readWebRuntimeConfigValueImpl(key);
