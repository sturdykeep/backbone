import 'dart:ui';

import 'package:backbone/message.dart';
import 'package:backbone/realm.dart';

typedef SystemResult = dynamic;

/// A system is a function that gets applied to nodes in the realm.
/// Systems are applied durning each update call of the related realm.
typedef System = SystemResult Function(Realm realm);

/// MessageSystems are used to process messages from a realm. Each update
/// call has a given amount of time to work on messages each update loop.
typedef MessageSystem = bool Function(Realm realm, AMessage message);

/// A system that handles rendering on the `Canvas`.
/// This system is called after all other systems have been called.
typedef RenderSystem = void Function(Realm realm, Canvas canvas);

final RegExp systemNameMatcher = RegExp('\'(.*?)\'');
String getSystemName(System system) {
  final match = systemNameMatcher.firstMatch(system.toString());
  if (match != null) {
    return match.group(1)!;
  }
  return 'Unknown System';
}
