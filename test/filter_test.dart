import 'package:backbone/archetype.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:flutter_test/flutter_test.dart';

class TestComponentA extends ATrait {}

class TestComponentB extends ATrait {}

class TestComponentC extends ATrait {}

class TestComponentD extends ATrait {}

void main() {
  group('Filter', () {
    test('[a, b, c] has [a]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = Has([TestComponentA]);
      expect(filter.matches(archetype), true);
    });
    test('[a, b, c] has [a, b]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = Has([TestComponentA, TestComponentB]);
      expect(filter.matches(archetype), true);
    });
    test('[a, b, c] has [a, b, c]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = Has([TestComponentA, TestComponentB, TestComponentC]);
      expect(filter.matches(archetype), true);
    });
    test('[a, b, c] doesn\'t have [a, b, c, d]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter =
          Has([TestComponentA, TestComponentB, TestComponentC, TestComponentD]);
      expect(filter.matches(archetype), false);
    });
    test('[a, b, c] has [a] or [b]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = Or([
        Has([TestComponentA]),
        Has([TestComponentB])
      ]);
      expect(filter.matches(archetype), true);
    });
    test('[a] has [a] or [b]', () {
      var archetype = Archetype([TestComponentA]);
      var filter = Or([
        Has([TestComponentA]),
        Has([TestComponentB])
      ]);
      expect(filter.matches(archetype), true);
    });
    test('[b] has [a] or [b]', () {
      var archetype = Archetype([TestComponentB]);
      var filter = Or([
        Has([TestComponentA]),
        Has([TestComponentB])
      ]);
      expect(filter.matches(archetype), true);
    });
    test('[c] doesn\'t have [a] or [b]', () {
      var archetype = Archetype([TestComponentC]);
      var filter = Or([
        Has([TestComponentA]),
        Has([TestComponentB])
      ]);
      expect(filter.matches(archetype), false);
    });
    test('[a, b, c] has [a] and [c]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = And([
        Has([TestComponentA]),
        Has([TestComponentC])
      ]);
      expect(filter.matches(archetype), true);
    });
    test('[b] doesn\'t have [a] and [b]', () {
      var archetype = Archetype([TestComponentB]);
      var filter = And([
        Has([TestComponentA]),
        Has([TestComponentB])
      ]);
      expect(filter.matches(archetype), false);
    });
    test('[a, c] has [a, c] without [b]', () {
      var archetype = Archetype([TestComponentA, TestComponentC]);
      var filter = And([
        Has([TestComponentA, TestComponentC]),
        Without([TestComponentB])
      ]);
      expect(filter.matches(archetype), true);
    });
    test('[a, b, c] doesn\'t have [a, c] without [b]', () {
      var archetype =
          Archetype([TestComponentA, TestComponentB, TestComponentC]);
      var filter = And([
        Has([TestComponentA, TestComponentC]),
        Without([TestComponentB])
      ]);
      expect(filter.matches(archetype), false);
    });
  });
}
