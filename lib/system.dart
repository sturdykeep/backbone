import 'package:backbone/message.dart';
import 'package:backbone/world.dart';

typedef System = void Function(World world);
typedef MessageSystem = bool Function(World world, AMessage message);
