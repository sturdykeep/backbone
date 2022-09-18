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

  var types = <Type>[];
  late final String name;

  get length => types.length;

  Archetype(Iterable<Type> types) {
    var sorted = types.toList();
    sorted.sort((a, b) => a.toString().compareTo(b.toString()));
    this.types = sorted;
    name = sorted.join(',');
  }

  bool includes(Type type) => types.contains(type);
  bool includesAll(Iterable<Type> types) => types.every(includes);
  bool includesOther(Archetype other) => includesAll(other.types);
  bool includesAny(Iterable<Type> types) => types.any(includes);
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
    if (other.types.length == types.length) {
      equals = true;
      for (var i = 0; i < types.length; i++) {
        if (other.types[i] != types[i]) {
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
