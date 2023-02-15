import 'package:backbone/builders.dart';
import 'package:backbone/prelude/text/system.dart';
import 'package:backbone/prelude/text/trait.dart';

/// Adding trait and system for default text handling
void textPlugin(RealmBuilder builder) {
  builder.withTrait(TextTrait);
  builder.withSystem(textSystem);
}
