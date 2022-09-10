import 'package:backbone/message.dart';
import 'package:backbone/realm.dart';
import 'package:example/messages.dart';

bool removeBounceMessageSystem(Realm realm, AMessage message) {
  if (message is RemoveBouncerMessage) {
    message.bouncer.removeFromParent();
    return true;
  }
  return false;
}
