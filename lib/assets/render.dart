import 'dart:ui';

import 'package:backbone/assets/stack.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

class SpriteBatchStack {
  final List<Image> images;
  final Color defaultColor;
  final BlendMode defaultBlendMode;
  final RSTransform? defaultTransform;
  final bool useAtlas;

  late List<SpriteBatch> _batches;

  SpriteBatchStack(this.images,
      {this.defaultColor = const Color(0x00000000),
      this.defaultBlendMode = BlendMode.srcOver,
      this.defaultTransform,
      this.useAtlas = true}) {
    _batches = images
        .map((image) => SpriteBatch(image,
            defaultColor: defaultColor,
            defaultBlendMode: defaultBlendMode,
            defaultTransform: defaultTransform,
            useAtlas: useAtlas))
        .toList();
  }

  void clear() {
    for (var batch in _batches) {
      batch.clear();
    }
  }

  void add(
      {required AtlasStackImage source,
      double scale = 1.0,
      Vector2? anchor,
      double rotation = 0,
      Vector2? offset,
      Color? color}) {
    final batch = _batches[source.atlasIndex];
    final rect = source.atlasRect;
    batch.add(
        source: rect,
        scale: scale,
        anchor: anchor,
        rotation: rotation,
        offset: offset,
        color: color);
  }

  void addTransform(
      {required AtlasStackImage source, RSTransform? transform, Color? color}) {
    final batch = _batches[source.atlasIndex];
    final rect = source.atlasRect;
    batch.addTransform(source: rect, transform: transform, color: color);
  }

  void render(Canvas canvas,
      {BlendMode? blendMode, Rect? cullRect, Paint? paint}) {
    for (var batch in _batches) {
      batch.render(canvas,
          blendMode: blendMode, cullRect: cullRect, paint: paint);
    }
  }
}
