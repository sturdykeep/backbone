import 'package:backbone/message.dart';
import 'package:example/bouncer.dart';

class RemoveBouncerMessage extends AMessage {
  final BouncerNode bouncer;

  RemoveBouncerMessage(this.bouncer);
}
