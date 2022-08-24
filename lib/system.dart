import 'package:backbone/message.dart';
import 'package:backbone/world.dart';

/// A system is a function that gets applied to nodes in the world.
/// Systems are applied durning each update call of the related world.
typedef System = void Function(World world);

/// MessageSystems are used to process messages from a world. Each update
/// call has a given amount of tim (????) to work on messages each update loop.
typedef MessageSystem = bool Function(World world, AMessage message);
