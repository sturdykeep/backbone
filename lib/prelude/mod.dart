import 'package:backbone/builders.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/sprite/mod.dart';
import 'package:backbone/prelude/text/mod.dart';
import 'package:backbone/prelude/transform.dart';

void defaultPlugin(RealmBuilder builder) {
  builder.withPlugin(transformPlugin);
  builder.withPlugin(inputPlugin);
  builder.withPlugin(textPlugin);
  builder.withPlugin(spritePlugin);
}
