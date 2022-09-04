import 'package:backbone/message.dart';
import 'package:backbone/world.dart';
import 'package:example/messages.dart';

bool removeBounceMessageSystem(World world, AMessage message) {
  if (message is RemoveBouncerMessage) {
    message.bouncer.removeFromParent();
    return true;
  }
  return false;
}
