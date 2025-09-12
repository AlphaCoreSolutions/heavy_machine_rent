import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';

bool get sensorsSupported {
  if (kIsWeb) return true; // sensors_plus_web
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS: // supported by sensors_plus_macos
      return true;
    default: // windows, linux, fuchsia
      return false;
  }
}

/// Safe, version-tolerant accelerometer stream.
/// Returns an empty stream on unsupported platforms so it never throws.
Stream<AccelerometerEvent> accelerometer$({
  Duration samplingPeriod = const Duration(milliseconds: 24),
}) {
  if (!sensorsSupported) {
    // No native impl -> never throw, just emit nothing
    return const Stream<AccelerometerEvent>.empty();
  }
  try {
    // Newer sensors_plus
    return accelerometerEventStream(samplingPeriod: samplingPeriod);
  } catch (_) {
    // Older sensors_plus fallback
    return accelerometerEvents.handleError((_) {});
  }
}
