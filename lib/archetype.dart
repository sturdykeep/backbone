import 'dart:collection';

/// Used in the Realm to speed up queries for nodes
class Archetype {
  static List<Archetype> allCombinations(Iterable<Type> types) {
    // Creates archetypes from all possible combinations of sorted by name types
    // e.g. [A, B, C] => [A], [B], [C], [A, B], [A, C], [B, C], [A, B, C]
    var archetypes = <Archetype>[];
    var typesSorted = types.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
    var resultArray = <List<Type>>[];
    var tempArray = <List<Type>>[];
    for (var i = 0; i < typesSorted.length; i++) {
      tempArray = [
        [typesSorted[i]]
      ];
      var index = 0;
      while (index < resultArray.length) {
        tempArray.add(resultArray[index] + [typesSorted[i]]);
        index++;
      }
      resultArray = resultArray + tempArray;
    }

    for (var i = 0; i < resultArray.length; i++) {
      archetypes.add(Archetype(resultArray[i]));
    }

    archetypes.sort((a, b) => a.length.compareTo(b.length));
    return archetypes;
  }

  static HashMap<Type, int> _typeToIndex = HashMap<Type, int>();
  static int toIndex(Type type) {
    if (_typeToIndex.containsKey(type)) {
      return _typeToIndex[type]!;
    }
    var index = _typeToIndex.length;
    _typeToIndex[type] = index;
    return index;
  }

  var types = <Type>[];
  var typesAsString = <String>[];
  var typesAsIndices = <int>[];
  int typesSum = 0;
  late final String name;

  get length => types.length;

  Archetype(Iterable<Type> types) {
    var sorted = types.toList();
    sorted.sort((a, b) => a.toString().compareTo(b.toString()));
    this.types = sorted;
    name = sorted.join(',');
    typesAsString = sorted.map((e) => e.toString()).toList();
    typesAsIndices = sorted.map((e) => toIndex(e)).toList();
    typesSum = typesAsIndices.fold(0, (a, b) => a + b);
  }

  bool includesIndex(int index) => typesAsIndices.contains(index);
  bool includes(Type type) => includesIndex(toIndex(type));
  bool includesAllIndices(List<int> indices) {
    final length = indices.length;
    for (var i = 0; i < length; i++) {
      if (typesAsIndices.contains(indices[i]) == false) {
        return false;
      }
    }
    return true;
  }

  bool includesAll(Iterable<Type> types) =>
      includesAllIndices(types.map((e) => toIndex(e)).toList());
  bool includesOther(Archetype other) =>
      includesAllIndices(other.typesAsIndices);
  bool includesAnyIndices(List<int> indices) {
    final length = indices.length;
    for (var i = 0; i < length; i++) {
      if (typesAsIndices.contains(indices[i])) {
        return true;
      }
    }
    return false;
  }

  bool includesAny(Iterable<Type> types) =>
      includesAnyIndices(types.map((e) => toIndex(e)).toList());

  Archetype concat(Archetype other) {
    var types = this.types + other.types;
    types = types.toSet().toList();
    return Archetype(types);
  }

  Archetype without(Archetype other) {
    var types = this.types.toSet();
    types.removeAll(other.types);
    return Archetype(types.toList());
  }

  @override
  bool operator ==(other) {
    if (other is! Archetype) return false;
    var equals = false;
    if (typesSum == other.typesSum) {
      equals = true;
      final length = types.length;
      for (var i = 0; i < length; i++) {
        if (other.typesAsIndices[i] != typesAsIndices[i]) {
          equals = false;
          break;
        }
      }
    }
    return equals;
  }

  @override
  String toString() {
    return 'Archetype($name)';
  }

  @override
  int get hashCode => name.hashCode;
}
