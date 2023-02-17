import 'dart:ui';

import 'package:backbone/assets/mod.dart';

class AtlasStackImage {
  final int atlasIndex;
  final Rect atlasRect;

  AtlasStackImage(this.atlasIndex, this.atlasRect);
}

class AtlasStackBuilder {
  final int maxWidth;
  final int maxHeight;
  final List<AtlasBuilder> _atlases = [];

  AtlasStackBuilder(this.maxWidth, this.maxHeight);

  /// Tries to fit the image into one of the atlases, if fails, adds a new atlas.
  AtlasStackImage addImage(Image image) {
    for (var i = 0; i < _atlases.length; i++) {
      var atlas = _atlases[i];
      var rect = atlas.addImage(image);
      if (rect != null) {
        return AtlasStackImage(i, rect);
      }
    }

    var atlas = AtlasBuilder(maxWidth, maxHeight);
    var rect = atlas.addImage(image);
    if (rect == null) {
      throw Exception(
          'Failed to add image to atlas, image is too big (${image.width}x${image.height} vs ${atlas.maxWidth}x${atlas.maxHeight})');
    }
    _atlases.add(atlas);
    return AtlasStackImage(_atlases.length - 1, rect);
  }

  Future<List<Image>> build() async {
    var atlases = await Future.wait(_atlases.map((atlas) => atlas.build()));
    return atlases;
  }
}
