import 'package:opti_job_app/core/performance/web_vitals_telemetry_stub.dart'
    if (dart.library.js_interop) 'package:opti_job_app/core/performance/web_vitals_telemetry_web.dart';

void startWebVitalsTelemetry() => startWebVitalsTelemetryImpl();
