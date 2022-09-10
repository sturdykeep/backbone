import 'package:backbone/message.dart';
import 'package:backbone/realm.dart';

/// A system is a function that gets applied to nodes in the realm.
/// Systems are applied durning each update call of the related realm.
typedef System = void Function(Realm realm);

/// MessageSystems are used to process messages from a realm. Each update
/// call has a given amount of tim (????) to work on messages each update loop.
typedef MessageSystem = bool Function(Realm realm, AMessage message);
