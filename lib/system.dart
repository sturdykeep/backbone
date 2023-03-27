import 'package:backbone/message.dart';
import 'package:backbone/realm.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

typedef SystemResult = dynamic;

/// A system is a function that gets applied to nodes in the realm.
/// Systems are applied durning each update call of the related realm.
typedef System<T extends FlameGame> = SystemResult Function(Realm<T> realm);

/// MessageSystems are used to process messages from a realm. Each update
/// call has a given amount of time to work on messages each update loop.
typedef MessageSystem<T extends FlameGame> = bool Function(
    Realm<T> realm, AMessage message);

final RegExp systemNameMatcher = RegExp('\'(.*?)\'');

String getSystemName<T extends FlameGame>(System<T> system) {
  if (kIsWeb && kDebugMode) {
    try {
      return system
          .toString()
          .split("{")[0]
          .split("function")[1]
          .trim()
          .split("(")[0]
          .trim();
    } catch (ex) {
      // Not important fallback below will take care
    }
  }
  final match = systemNameMatcher.firstMatch(system.toString());
  if (match != null) {
    return match.group(1)!;
  }
  return 'Unknown System';
}
