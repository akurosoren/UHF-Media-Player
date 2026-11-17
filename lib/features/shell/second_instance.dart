import 'dart:async';
import 'package:flutter/services.dart';

import '../../core/system/launch_args.dart';
import '../player/player_controller.dart';
import 'shell_controller.dart';

const MethodChannel _runnerSecondInstanceChannel = MethodChannel('uhf_media/second_instance');

/// Bridges runner WM_COPYDATA / single-instance events (called before the UI exists) and the app.
abstract final class SecondInstance {
  static void Function(List<String> args)? _listener;
  static final List<List<String>> _pending = [];
  static bool _channelInitialized = false;

  static void initChannel() {
    if (_channelInitialized) return;
    _channelInitialized = true;
    _runnerSecondInstanceChannel.setMethodCallHandler((call) async {
      if (call.method == 'openArgs' && call.arguments is List) {
        final list = (call.arguments as List).map((o) => o.toString()).toList();
        deliver(list);
      }
    });
  }

  static void deliver(List<String> args) {
    final listener = _listener;
    if (listener == null) {
      _pending.add(args);
    } else {
      listener(args);
    }
  }

  static set listener(void Function(List<String> args)? value) {
    _listener = value;
    if (value == null) return;
    final queued = List.of(_pending);
    _pending.clear();
    for (final args in queued) {
      value(args);
    }
  }
}

void Function(List<String>) secondInstanceHandler({
  required ShellController shell,
  required PlayerController player,
  bool Function(String path)? exists,
}) {
  return (args) {
    unawaited(shell.bringToFront());
    final file = firstExistingFile(args, exists: exists);
    if (file != null) unawaited(player.open(file));
  };
}
