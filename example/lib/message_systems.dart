import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/realm.dart';
import 'package:example/drag_bar.dart';
import 'package:example/messages.dart';

bool removeBounceMessageSystem(Realm realm, AMessage message) {
  if (message is RemoveBouncerMessage) {
    message.bouncer.removeFromParent();
    return true;
  }
  return false;
}

bool resizeMessageSystem(Realm realm, AMessage message) {
  if (message is GameResizseMessage) {
    final nodes = realm.query(Has([GameResizeTrait]));
    for (var element in nodes) {
      element.get<GameResizeTrait>().resized();
    }
    return true;
  }
  return false;
}
