import 'package:flutter/foundation.dart';

bool internalDebugLogEnabled = false;

void debugLog(obj) {
  if (kDebugMode && internalDebugLogEnabled) {
    // ignore: avoid_print
    print(obj);
  }
}
