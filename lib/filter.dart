import 'package:backbone/archetype.dart';

/// Base class for any filter in realms
abstract class AFilter {
  bool matches(Archetype archetype);
}

/// Checks if all types are included
class Has extends AFilter {
  final Iterable<Type> components;
  Has(this.components);
  @override
  bool matches(Archetype archetype) => archetype.includesAll(components);
}

/// Check if at least one type is inlcuded
class HasAny extends AFilter {
  final Iterable<Type> components;
  HasAny(this.components);
  @override
  bool matches(Archetype archetype) => archetype.includesAny(components);
}

/// Check that none of the types are included
class Without extends AFilter {
  final Iterable<Type> components;
  Without(this.components);
  @override
  bool matches(Archetype archetype) =>
      archetype.includesAny(components) == false;
}

/// Logical and multiple filters together
class And extends AFilter {
  final Iterable<AFilter> filters;
  And(this.filters);
  @override
  bool matches(Archetype archetype) {
    for (var filter in filters) {
      if (filter.matches(archetype) == false) {
        return false;
      }
    }
    return true;
  }
}

/// Logical Or multiple filters together
class Or extends AFilter {
  final Iterable<AFilter> filters;
  Or(this.filters);
  @override
  bool matches(Archetype archetype) {
    for (var filter in filters) {
      if (filter.matches(archetype)) {
        return true;
      }
    }
    return false;
  }
}
