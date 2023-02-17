import 'package:backbone/assets/rect.dart';
import 'package:flame/image_composition.dart';

class AtlasBuilderImage {
  final Rect rect;
  final Image image;

  AtlasBuilderImage(this.rect, this.image);
}

class AtlasBuilder {
  final int maxWidth;
  final int maxHeight;
  final List<AtlasBuilderImage> _images = [];
  final Rect _atlasRect;

  AtlasBuilder(this.maxWidth, this.maxHeight)
      : _atlasRect =
            Rect.fromLTWH(0, 0, maxWidth.toDouble(), maxHeight.toDouble());

  Rect? addImage(Image image) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    // Shortcut for empty atlases
    if (_images.isEmpty) {
      final spriteRect = Rect.fromLTWH(0, 0, width, height);
      _images.add(AtlasBuilderImage(spriteRect, image));
      return spriteRect;
    }

    // Find a spot for the image
    for (var y = 0; y < _atlasRect.height; y += 1) {
      for (var x = 0; x < _atlasRect.width; x += 1) {
        final spriteRect =
            Rect.fromLTWH(x.toDouble(), y.toDouble(), width, height);

        // Check if the sprite fits inside the atlas
        if (_atlasRect.containsOther(spriteRect) == false) {
          continue;
        }

        // Check if the sprite overlaps with any other sprites
        bool overlaps = false;
        for (final image in _images) {
          if (image.rect.overlaps(spriteRect)) {
            overlaps = true;
            break;
          }
        }
        if (overlaps == false) {
          _images.add(AtlasBuilderImage(spriteRect, image));
          return spriteRect;
        }
      }
    }

    return null;
  }

  Future<Image> build() async {
    final imageComposition = ImageComposition();

    for (var image in _images) {
      imageComposition.add(
          image.image, Vector2(image.rect.left, image.rect.top));
    }

    return imageComposition.compose();
  }
}
