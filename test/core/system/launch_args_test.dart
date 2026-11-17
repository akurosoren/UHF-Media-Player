import 'package:flutter_test/flutter_test.dart';
import 'package:uhf_media/core/system/launch_args.dart';

void main() {
  group('cleanLaunchArg', () {
    test('strips double quotes', () {
      expect(cleanLaunchArg('"C:\\path\\video.mp4"'), equals('C:\\path\\video.mp4'));
    });

    test('strips single quotes', () {
      expect(cleanLaunchArg("'C:\\path\\video.mp4'"), equals('C:\\path\\video.mp4'));
    });

    test('trims surrounding whitespace and quotes', () {
      expect(cleanLaunchArg('  "C:\\path\\video.mp4"  '), equals('C:\\path\\video.mp4'));
    });

    test('preserves unquoted path', () {
      expect(cleanLaunchArg('C:\\path\\video.mp4'), equals('C:\\path\\video.mp4'));
    });
  });

  group('firstExistingFile', () {
    test('skips dash flags and Windows slash switches', () {
      final existing = {'C:\\media\\video.mp4'};
      final args = ['--profile', '/prefetch:1', '-v', 'C:\\media\\video.mp4'];

      final result = firstExistingFile(args, exists: existing.contains);
      expect(result, isNotNull);
      expect(result, contains('video.mp4'));
    });

    test('resolves file passed with surrounding quotes', () {
      final existing = {'C:\\media\\video 1.mp4'};
      final args = ['"C:\\media\\video 1.mp4"'];

      final result = firstExistingFile(args, exists: existing.contains);
      expect(result, isNotNull);
      expect(result, contains('video 1.mp4'));
    });

    test('returns null when no existing file is found', () {
      final args = ['--flag', '/switch', 'non_existent.mp4'];
      final result = firstExistingFile(args, exists: (_) => false);
      expect(result, isNull);
    });
  });
}
