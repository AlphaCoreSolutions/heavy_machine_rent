import 'package:flutter/foundation.dart';

/// ChangeNotifier that never notifies after dispose().
abstract class SafeNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @protected
  void notifySafe() {
    if (!_disposed) notifyListeners();
  }
}
