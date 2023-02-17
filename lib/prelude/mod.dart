import 'package:backbone/builders.dart';
import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/sprite/mod.dart';
import 'package:backbone/prelude/text/mod.dart';
import 'package:backbone/prelude/transform.dart';

void defaultPlugin(RealmBuilder builder) {
  builder.withTrait(NodeTrait);
  builder.withPlugin(transformPlugin);
  builder.withPlugin(inputPlugin);
  builder.withPlugin(textPlugin);
  builder.withPlugin(spritePlugin);
  builder.withPlugin(renderPlugin);
}
