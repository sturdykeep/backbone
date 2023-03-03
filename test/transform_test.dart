import 'dart:math';

import 'package:backbone/prelude/transform.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transform', () {
    test('zero transform doesn\'t transform anything', () {
      final transform = TransformTrait();
      expect(transform.transformMatrix, Matrix4.identity());
    });
    test('translate', () {
      final transform = TransformTrait();
      transform.position = Vector2(10, 20);

      final pointA = Vector2(1, 1);
      final pointB = Vector2(2, 2);

      final transformedA = transform.transformMatrix.transform2(pointA);
      final transformedB = transform.transformMatrix.transform2(pointB);

      expect(transformedA, Vector2(11, 21));
      expect(transformedB, Vector2(12, 22));
    });
    test('scale', () {
      final transform = TransformTrait();
      transform.scale = Vector2(10, 20);
      final pointA = Vector2(1, 1);
      final pointB = Vector2(2, 2);

      final transformedA = transform.transformMatrix.transform2(pointA);
      final transformedB = transform.transformMatrix.transform2(pointB);

      expect(transformedA, Vector2(10, 20));
      expect(transformedB, Vector2(20, 40));
    });
    test('rotate', () {
      final transform = TransformTrait();
      transform.rotation = 90 * (pi / 180);
      final pointA = Vector2(1, 1);
      final pointB = Vector2(2, 2);

      final transformedA = transform.transformMatrix.transform2(pointA);
      final transformedB = transform.transformMatrix.transform2(pointB);

      // Make sure to round to 2 decimals to avoid floating point errors
      final roundedA = Vector2(
        double.parse(transformedA.x.toStringAsFixed(2)),
        double.parse(transformedA.y.toStringAsFixed(2)),
      );
      final roundedB = Vector2(
        double.parse(transformedB.x.toStringAsFixed(2)),
        double.parse(transformedB.y.toStringAsFixed(2)),
      );

      expect(roundedA, Vector2(-1, 1));
      expect(roundedB, Vector2(-2, 2));
    });
    test('origin', () {
      final transform = TransformTrait();
      transform.anchor = Anchor.center;
      transform.size = Vector2(4, 4);

      final pointA = Vector2(1, 1);
      final pointB = Vector2(2, 2);

      final transformedA = transform.transformMatrix.transform2(pointA);
      final transformedB = transform.transformMatrix.transform2(pointB);

      expect(transformedA, Vector2(-1, -1));
      expect(transformedB, Vector2(0, 0));
    });
    test('rotate with origin', () {
      final transform = TransformTrait();
      transform.rotation = 90 * (pi / 180);
      transform.anchor = Anchor.center;
      transform.size = Vector2(4, 4);

      final pointA = Vector2(1, 1);
      final pointB = Vector2(2, 2);

      final transformedA = transform.transformMatrix.transform2(pointA);
      final transformedB = transform.transformMatrix.transform2(pointB);

      // Make sure to round to 2 decimals to avoid floating point errors
      final roundedA = Vector2(
        double.parse(transformedA.x.toStringAsFixed(2)),
        double.parse(transformedA.y.toStringAsFixed(2)),
      );
      final roundedB = Vector2(
        double.parse(transformedB.x.toStringAsFixed(2)),
        double.parse(transformedB.y.toStringAsFixed(2)),
      );

      expect(roundedA, Vector2(-1, 1));
      expect(roundedB, Vector2(0, 2));
    });
  });
}
