import 'dart:typed_data';

import 'package:flame/extensions.dart' show Vector2, Vector4, Matrix4;
import 'package:flutter/material.dart';
import 'package:ml_linalg/linalg.dart';
import 'package:vector_math/vector_math_operations.dart'
    show Matrix44SIMDOperations, Matrix44Operations;

// Included SIMD
extension Matrix4ToFloat32x4List on Matrix4 {
  Float32x4List toFloat32x4List() {
    final list = storage;
    final result = Float32x4List(4);
    for (var i = 0; i < 4; i++) {
      result[i] = Float32x4(
          list[i * 4], list[i * 4 + 1], list[i * 4 + 2], list[i * 4 + 3]);
    }
    return result;
  }

  void setFromFloat32x4List(Float32x4List list) {
    final result = Matrix4.zero();
    for (var i = 0; i < 4; i++) {
      final float32x4 = list[i];
      result.storage[i * 4] = float32x4.x;
      result.storage[i * 4 + 1] = float32x4.y;
      result.storage[i * 4 + 2] = float32x4.z;
      result.storage[i * 4 + 3] = float32x4.w;
    }
    setFrom(result);
  }
}

extension Float32x4ListAsMatrix on Float32x4List {
  Vector2 transform2(Vector2 vector) {
    final vector4Float32x4List =
        Float32x4List.fromList([Float32x4(vector.x, vector.y, 0, 0)]);
    final result = Float32x4List(1);
    Matrix44SIMDOperations.transform4(
        result, 0, this, 0, vector4Float32x4List, 0);
    return Vector2(result[0].x, result[0].y);
  }

  Float32x4List transformFloat32x4List(Float32x4List vector) {
    final result = Float32x4List(vector.length);
    Matrix44SIMDOperations.transform4(result, 0, this, 0, vector, 0);
    return result;
  }

  void transformFloat32x4ListSelf(Float32x4List vector) {
    Matrix44SIMDOperations.transform4(vector, 0, this, 0, vector, 0);
  }

  Float32x4List multiply(Float32x4List other) {
    final result = Float32x4List(4);
    Matrix44SIMDOperations.multiply(result, 0, this, 0, other, 0);
    return result;
  }

  void multiplySelf(Float32x4List other) {
    Matrix44SIMDOperations.multiply(this, 0, this, 0, other, 0);
  }

  Float32x4List inverse() {
    final matrix = Matrix4.identity()..setFromFloat32x4List(this);
    matrix.invert();
    return matrix.toFloat32x4List();
  }

  Float64List toFloat64List() {
    final result = Float64List(16);
    for (var i = 0; i < 4; i++) {
      final float32x4 = this[i];
      result[i * 4] = float32x4.x;
      result[i * 4 + 1] = float32x4.y;
      result[i * 4 + 2] = float32x4.z;
      result[i * 4 + 3] = float32x4.w;
    }
    return result;
  }
}

// ml_linalg SIMD
extension Matrix4ToMLMatrix on Matrix4 {
  Matrix toMatrix() {
    final list = storage;
    final result = Matrix.fromColumns([
      Vector.fromList([list[0], list[1], list[2], list[3]]),
      Vector.fromList([list[4], list[5], list[6], list[7]]),
      Vector.fromList([list[8], list[9], list[10], list[11]]),
      Vector.fromList([list[12], list[13], list[14], list[15]]),
    ]);
    return result;
  }

  void setFromMLMatrix(Matrix matrix) {
    final result = Matrix4.zero();
    final columns = matrix.columns.toList();
    for (var i = 0; i < 4; i++) {
      final column = columns[i];
      result.storage[i * 4] = column[0];
      result.storage[i * 4 + 1] = column[1];
      result.storage[i * 4 + 2] = column[2];
      result.storage[i * 4 + 3] = column[3];
    }
    setFrom(result);
  }
}

extension MLMatrixAsMatrix on Matrix {
  Vector2 transform2(Vector2 vector) {
    final vector4 = Vector.fromList([vector.x, vector.y, 1, 1]);
    final result = this * vector4;
    final resultVector = result.toVector();
    return Vector2(resultVector[0], resultVector[1]);
  }

  Matrix inverse() {
    return this.inverse();
  }
}
