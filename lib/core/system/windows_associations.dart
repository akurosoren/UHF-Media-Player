import 'dart:io';
import 'package:path/path.dart' as p;
import '../files/media_files.dart';

class WindowsAssociations {
  static const appName = 'UHF Media';
  static const progId = 'UHFMedia.Video';

  /// Registers UHF Media as a media player handler in HKCU (current user).
  /// This enables "Ouvrir avec" (Open With) and allows Windows 10/11 to set it
  /// as the default application without requiring administrator privileges.
  static Future<bool> registerUserAssociations({String? executablePath}) async {
    if (!Platform.isWindows) return false;

    final exe = executablePath ?? Platform.resolvedExecutable;
    if (exe.isEmpty || !File(exe).existsSync()) return false;

    final exeName = p.basename(exe);
    final openCommand = '"$exe" "%1"';
    final iconEntry = '"$exe",0';

    try {
      // 1. Applications\<exe> entry for Open With
      await _regAdd(r'HKCU\Software\Classes\Applications\' + exeName, 'FriendlyAppName', appName);
      await _regAdd(r'HKCU\Software\Classes\Applications\' + exeName + r'\shell\open\command', '', openCommand);

      // Supported types under Applications\<exe>
      final supportedTypesKey = r'HKCU\Software\Classes\Applications\' + exeName + r'\SupportedTypes';
      for (final ext in mediaExtensions) {
        await _regAdd(supportedTypesKey, '.$ext', '');
      }

      // 2. ProgID: UHFMedia.Video
      await _regAdd(r'HKCU\Software\Classes\' + progId, '', 'UHF Media Video');
      await _regAdd(r'HKCU\Software\Classes\' + progId, 'FriendlyTypeName', 'UHF Media Video');
      await _regAdd(r'HKCU\Software\Classes\' + progId + r'\DefaultIcon', '', iconEntry);
      await _regAdd(r'HKCU\Software\Classes\' + progId + r'\shell\open\command', '', openCommand);

      // 3. OpenWithProgids for each media extension
      for (final ext in mediaExtensions) {
        await _regAdd(r'HKCU\Software\Classes\.' + ext + r'\OpenWithProgids', progId, '');
        await _regAdd(r'HKCU\Software\Classes\.' + ext + r'\OpenWithProgids', r'Applications\' + exeName, '');
      }

      // 4. RegisteredApplications so Windows Settings displays it under Default Apps
      const capabilitiesKey = r'Software\Clients\Media\UHFMedia\Capabilities';
      await _regAdd(r'HKCU\Software\RegisteredApplications', appName, capabilitiesKey);

      // 5. Capabilities
      const fullCapKey = r'HKCU\' + capabilitiesKey;
      await _regAdd(fullCapKey, 'ApplicationName', appName);
      await _regAdd(fullCapKey, 'ApplicationDescription', 'UHF Media Video Player');
      for (final ext in mediaExtensions) {
        await _regAdd(fullCapKey + r'\FileAssociations', '.$ext', progId);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _regAdd(String key, String valueName, String data) async {
    final args = <String>['add', key, '/f'];
    if (valueName.isEmpty) {
      args.add('/ve');
    } else {
      args.addAll(['/v', valueName]);
    }
    args.addAll(['/t', 'REG_SZ', '/d', data]);
    await Process.run('reg', args);
  }
}
