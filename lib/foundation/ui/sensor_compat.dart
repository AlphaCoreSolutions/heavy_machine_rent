import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';

bool get sensorsSupported {
  if (kIsWeb) return true; // web impl OK
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.macOS:
      // Temporarily disabled: macOS build throwing MissingPluginException for
      // setAccelerationSamplingPeriod (plugin not wired / version mismatch).
      // Returning false prevents subscription & platform channel calls.
      return false;
    default:
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
    // Attempt newer API
    return accelerometerEventStream(samplingPeriod: samplingPeriod)
        .handleError((_) {});
  } catch (_) {
    try {
      // Fallback to legacy stream
      return accelerometerEvents.handleError((_) {});
    } catch (_) {
      // Final safeguard
      return const Stream<AccelerometerEvent>.empty();
    }
  }
}
