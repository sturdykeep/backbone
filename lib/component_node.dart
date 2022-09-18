import 'package:backbone/node.dart';
import 'package:flame/components.dart';

/// Default node that comes without any traits. This node is based on the
/// component class of Flame.
abstract class ComponentNode extends Component with HasGameRef, ANode {}
