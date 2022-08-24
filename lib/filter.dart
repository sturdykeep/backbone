import 'package:backbone/archetype.dart';

abstract class AFilter {
  bool matches(Archetype archetype);
}

class Has extends AFilter {
  final Iterable<Type> components;
  Has(this.components);
  @override
  bool matches(Archetype archetype) => archetype.includesAll(components);
}

class HasAny extends AFilter {
  final Iterable<Type> components;
  HasAny(this.components);
  @override
  bool matches(Archetype archetype) => archetype.includesAny(components);
}

class Without extends AFilter {
  final Iterable<Type> components;
  Without(this.components);
  @override
  bool matches(Archetype archetype) =>
      archetype.includesAny(components) == false;
}

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
