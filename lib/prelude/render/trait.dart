import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/trait.dart';

class Renderable extends Trait {
  Visual? visual;
  int? overridePriority;

  Renderable({this.visual, this.overridePriority});

  T as<T extends Visual>() => visual as T;
}
