import 'package:backbone/archetype.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Archetype', () {
    test('single equals', () {
      var archetype = Archetype([String]);
      var other = Archetype([String]);
      expect(archetype == other, true);
    });
    test('single not equals', () {
      var archetype = Archetype([String]);
      var other = Archetype([int]);
      expect(archetype == other, false);
    });
    test('multiple equals', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([String, int]);
      expect(archetype == other, true);
    });
    test('multiple not equals', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([String, double]);
      expect(archetype == other, false);
    });
    test('multiple different order equals', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([int, String]);
      expect(archetype == other, true);
    });
    test('multiple different order not equals', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([int, String, double]);
      expect(archetype == other, false);
    });
    test('includes type', () {
      var archetype = Archetype([String, int]);
      expect(archetype.includes(String), true);
      expect(archetype.includes(int), true);
      expect(archetype.includes(double), false);
    });
    test('includes all types', () {
      var archetype = Archetype([String, int]);
      expect(archetype.includesAll([String, int]), true);
      expect(archetype.includesAll([String, double]), false);
    });
    test('includes any types', () {
      var archetype = Archetype([String, int]);
      expect(archetype.includesAny([String, int]), true);
      expect(archetype.includesAny([String, double]), true);
      expect(archetype.includesAny([double, int]), true);
      expect(archetype.includesAny([double, double]), false);
    });
    test('includes any types with empty', () {
      var archetype = Archetype([]);
      expect(archetype.includesAny([String, int]), false);
      expect(archetype.includesAny([String, double]), false);
      expect(archetype.includesAny([double, int]), false);
      expect(archetype.includesAny([double, double]), false);
    });
    test('includes smaller archetype', () {
      var archetype = Archetype([String, int, double]);
      var other = Archetype([String, int]);
      expect(archetype.includesOther(other), true);
    });
    test('doesn\'t include bigger archetype', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([String, int, double]);
      expect(archetype.includesOther(other), false);
    });

    // Combinations
    test('all combinations one', () {
      var types = [String];
      var archetypes = Archetype.allCombinations(types);
      expect(archetypes.length, 1);
      expect(archetypes[0].types.length, 1);
      expect(archetypes[0].types[0], String);
    });
    test('all combinations two', () {
      var types = [String, int];
      var archetypes = Archetype.allCombinations(types);
      expect(archetypes.length, 3);
      expect(archetypes[0].types.length, 1);
      expect(archetypes[0].types[0], String);
      expect(archetypes[1].types.length, 1);
      expect(archetypes[1].types[0], int);
      expect(archetypes[2].types.length, 2);
      expect(archetypes[2].types[0], String);
      expect(archetypes[2].types[1], int);
    });
    test('all combinations two other order', () {
      var types = [int, String];
      var archetypes = Archetype.allCombinations(types);
      expect(archetypes.length, 3);
      expect(archetypes[0].types.length, 1);
      expect(archetypes[0].types[0], String);
      expect(archetypes[1].types.length, 1);
      expect(archetypes[1].types[0], int);
      expect(archetypes[2].types.length, 2);
      expect(archetypes[2].types[0], String);
      expect(archetypes[2].types[1], int);
    });
    test('all combinations three', () {
      var types = [String, int, double];
      var archetypes = Archetype.allCombinations(types);
      expect(archetypes.length, 7);
      expect(archetypes[0].types.length, 1);
      expect(archetypes[0].types[0], String);
      expect(archetypes[1].types.length, 1);
      expect(archetypes[1].types[0], double);
      expect(archetypes[2].types.length, 1);
      expect(archetypes[2].types[0], int);
      expect(archetypes[3].types.length, 2);
      expect(archetypes[3].types[0], String);
      expect(archetypes[3].types[1], double);
      expect(archetypes[4].types.length, 2);
      expect(archetypes[4].types[0], String);
      expect(archetypes[4].types[1], int);
      expect(archetypes[5].types.length, 2);
      expect(archetypes[5].types[0], double);
      expect(archetypes[5].types[1], int);
      expect(archetypes[6].types.length, 3);
      expect(archetypes[6].types[0], String);
      expect(archetypes[6].types[1], double);
      expect(archetypes[6].types[2], int);
    });
    test('list contains', () {
      var types = [String, int, double];
      var archetypes = Archetype.allCombinations(types);
      var archetype = Archetype([String, int, double]);
      var archetypeString = Archetype([String]);
      var archetypeInt = Archetype([int]);
      var archetypeDouble = Archetype([double]);
      expect(archetypes.contains(archetype), true);
      expect(archetypes.contains(archetypeString), true);
      expect(archetypes.contains(archetypeInt), true);
      expect(archetypes.contains(archetypeDouble), true);
    });
    test('list does not contain', () {
      var types = [String, int, double];
      var archetypes = Archetype.allCombinations(types);
      var archetype = Archetype([String, int, double, bool]);
      var archetypeBool = Archetype([bool]);
      expect(archetypes.contains(archetype), false);
      expect(archetypes.contains(archetypeBool), false);
    });
    test('concat two archetypes', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([int, double]);
      var concatenated = archetype.concat(other);
      expect(concatenated.types.length, 3);
      expect(concatenated.types[0], String);
      expect(concatenated.types[1], double);
      expect(concatenated.types[2], int);
    });
    test('exclude archetype from another', () {
      var archetype = Archetype([String, int]);
      var other = Archetype([int, double]);
      var excluded = archetype.without(other);
      expect(excluded.types.length, 1);
      expect(excluded.types[0], String);
    });
  });
}
