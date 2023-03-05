import 'package:backbone/realm.dart';
import 'package:backbone/realm_mixin.dart';
import 'package:flame/game.dart';

abstract class PlaygroundGame extends FlameGame with HasRealm {
  PlaygroundGame();

  // Abstract function that builds the Realm
  Realm realmBuilder();

  @override
  Future<void> onLoad() async {
    realm = realmBuilder();
    add(realm);
    realmReady = true;
  }
}
