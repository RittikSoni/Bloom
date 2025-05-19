import 'dart:io';

class Helper {
  static String get getFFmpegEngine {
    if (Platform.isWindows) {
      return 'gdigrab';
    } else if (Platform.isMacOS) {
      return 'avfoundation';
    } else if (Platform.isLinux) {
      return 'x11grab';
    }
    return 'gdigrab'; // Default to Windows if platform is unknown
  }
}
