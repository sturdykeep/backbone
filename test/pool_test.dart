import 'package:backbone/pool.dart';
import 'package:flutter_test/flutter_test.dart';

class SimpleTestObject {
  int value = 0;
}

void main() {
  group('Pool', () {
    test('pool can be created', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      expect(pool, isNotNull);
      expect(pool.size, 0);
    });
    test('can get object from pool', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      final obj = pool.get();
      expect(obj, isNotNull);
      expect(obj.value, 0);
      expect(pool.size, 0);
    });
    test('can release object to pool', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      final obj = pool.get();
      expect(obj, isNotNull);
      expect(obj.value, 0);
      expect(pool.size, 0);
      pool.release(obj);
      expect(pool.size, 1);
    });
    test('can reuse object from pool', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      final obj = pool.get();
      expect(obj, isNotNull);
      expect(obj.value, 0);
      expect(pool.size, 0);
      pool.release(obj);
      expect(pool.size, 1);
      final obj2 = pool.get();
      expect(obj2, isNotNull);
      expect(obj2.value, 0);
      expect(pool.size, 0);
    });
    test('resetter method resets the object', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      final obj = pool.get();
      expect(obj, isNotNull);
      expect(obj.value, 0);
      expect(pool.size, 0);
      obj.value = 1;
      pool.release(obj);
      expect(pool.size, 1);
      final obj2 = pool.get();
      expect(obj2, isNotNull);
      expect(obj2.value, 0);
      expect(pool.size, 0);
    });
    test('trying to release same object twice doesn\'t throw', () {
      final pool = Pool<SimpleTestObject>(() => SimpleTestObject(), (obj) => obj.value = 0);
      final obj = pool.get();
      expect(obj, isNotNull);
      expect(obj.value, 0);
      expect(pool.size, 0);
      var wasAdded = pool.release(obj);
      expect(pool.size, 1);
      expect(wasAdded, isTrue);
      wasAdded = pool.release(obj);
      expect(pool.size, 1);
      expect(wasAdded, isFalse);
    });
  });
}
