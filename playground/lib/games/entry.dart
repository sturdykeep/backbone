import 'package:backbone/realm.dart';
import 'package:backbone/realm_mixin.dart';
import 'package:flame/game.dart';

class PlaygroundGame extends FlameGame with HasRealm {
  final Realm Function() realmBuilder;

  PlaygroundGame(this.realmBuilder);

  @override
  Future<void> onLoad() async {
    realm = realmBuilder();
    add(realm);
    realmReady = true;
  }
}
