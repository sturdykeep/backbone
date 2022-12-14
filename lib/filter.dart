import 'package:backbone/archetype.dart';

/// Base class for any filter in realms
abstract class AFilter {
  bool matches(Archetype archetype);
}

/// Checks if all types are included
class Has extends AFilter {
  final List<Type> components;
  late final List<int> componentsAsIndices;
  Has(this.components) {
    componentsAsIndices = components.map((e) => Archetype.toIndex(e)).toList();
  }
  @override
  bool matches(Archetype archetype) =>
      archetype.includesAllIndices(componentsAsIndices);
}

/// Check if at least one type is inlcuded
class HasAny extends AFilter {
  final List<Type> components;
  late final List<int> componentsAsIndices;
  HasAny(this.components) {
    componentsAsIndices = components.map((e) => Archetype.toIndex(e)).toList();
  }
  @override
  bool matches(Archetype archetype) =>
      archetype.includesAnyIndices(componentsAsIndices);
}

/// Check that none of the types are included
class Without extends AFilter {
  final List<Type> components;
  late final List<int> componentsAsIndices;
  Without(this.components) {
    componentsAsIndices = components.map((e) => Archetype.toIndex(e)).toList();
  }
  @override
  bool matches(Archetype archetype) =>
      archetype.includesAnyIndices(componentsAsIndices) == false;
}

/// Logical and multiple filters together
class And extends AFilter {
  final List<AFilter> filters;
  And(this.filters);
  @override
  bool matches(Archetype archetype) {
    final length = filters.length;
    for (var i = 0; i < length; i++) {
      final filter = filters[i];
      if (filter.matches(archetype) == false) {
        return false;
      }
    }
    return true;
  }
}

/// Logical Or multiple filters together
class Or extends AFilter {
  final List<AFilter> filters;
  Or(this.filters);
  @override
  bool matches(Archetype archetype) {
    final length = filters.length;
    for (var i = 0; i < length; i++) {
      final filter = filters[i];
      if (filter.matches(archetype)) {
        return true;
      }
    }
    return false;
  }
}
