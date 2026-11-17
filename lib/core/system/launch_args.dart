import 'dart:io';
import 'package:path/path.dart' as p;

/// Strips surrounding quotes and whitespace from an argument passed by Windows shell.
String cleanLaunchArg(String raw) {
  var s = raw.trim();
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

/// First command-line argument that names an existing file; flags are skipped.
String? firstExistingFile(List<String> args, {bool Function(String path)? exists}) {
  final test = exists ?? ((path) => File(path).existsSync());
  for (final raw in args) {
    final arg = cleanLaunchArg(raw);
    if (arg.isEmpty) continue;
    // Skip command-line switches (-flag, --flag, /switch)
    if (arg.startsWith('-') || arg.startsWith('/')) continue;
    if (test(arg)) return p.normalize(arg);
  }
  return null;
}
