import 'dart:ui';

extension RectContains on Rect {
  bool containsOther(Rect other) {
    return contains(other.topLeft) &&
        contains(other.topRight) &&
        contains(other.bottomLeft) &&
        contains(other.bottomRight);
  }
}
