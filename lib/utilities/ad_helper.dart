import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  AdHelper._();

  static const String nativeAdFactoryId = 'shoqlistNativeAd';

  static String get appId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6556175768591042~6528645139';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-6556175768591042~1138242915';
    }
    throw UnsupportedError('Unsupported platform for AdMob');
  }

  /// Returns the native ad unit ID for the current platform.
  /// In debug builds, Google's official test IDs are used to avoid invalid
  /// traffic on real ad units.
  static String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-6556175768591042/2563852689'
        : 'ca-app-pub-6556175768591042/2806547800';
  }
}
