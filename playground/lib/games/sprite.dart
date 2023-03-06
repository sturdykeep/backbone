import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/render/sprite.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:playground/games/base.dart';

class SpriteGame extends PlaygroundGame {
  late Sprite dashSprite;

  SpriteGame();

  Entity createSpriteEntity(Sprite sprite) {
    final entity = Entity();
    final transform = Transform();
    transform.size = Vector2.all(150);
    entity.add(transform);
    final renderTrait = Renderable();
    renderTrait.visual = SpriteVisual(sprite: sprite);
    entity.add(renderTrait);
    return entity;
  }

  @override
  Realm realmBuilder() {
    return RealmBuilder().withPlugin(defaultPlugin).build();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    dashSprite = await loadSprite('dash.png');

    // Create first dash sprite at 10,10
    final dash1 = createSpriteEntity(dashSprite);
    dash1.get<Transform>().position = Vector2(10, 10);
    realm.addEntity(dash1);

    // Same as before, but anchored to the center
    final dash2 = createSpriteEntity(dashSprite);
    dash2.get<Transform>().position = Vector2(10 + 150 / 2, 10 + 150 / 2);
    dash2.get<Transform>().anchor = Anchor.center;
    realm.addEntity(dash2);
  }
}
