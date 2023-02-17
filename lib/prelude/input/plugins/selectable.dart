import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flutter/services.dart';

/// Resource that holds a reference to [SelectableTrait] entities, which
/// are currently selected.
class Selection {
  bool Function(Pointer pointer)? onGlobalDeslect;

  /// The currently selected entities.
  final List<Entity> entities = [];

  /// Adds an entity to the selection.
  /// Returns true, if the entity was successfuly selected.
  bool add(Entity entity, {Pointer? pointer}) {
    final trait = entity.tryGet<SelectableTrait>();
    if (trait != null) {
      if (trait.selected == false) {
        final shouldGetSelected = trait.onSelected?.call(pointer);
        if (shouldGetSelected == true) {
          trait.selected = true;
          entities.add(entity);
          return true;
        }
      }
    }
    return false;
  }

  /// Removes an entity from the selection.
  /// Returns true if the entity was removed, false otherwise.
  /// If the entity was not in the selection, it will return false.
  bool remove(Entity entity, {Pointer? pointer}) {
    final trait = entity.tryGet<SelectableTrait>();
    if (trait != null) {
      if (trait.selected == true) {
        final shouldGetDeselected = trait.onDeselected?.call(pointer);
        if (shouldGetDeselected == true) {
          trait.selected = false;
          entities.remove(entity);
          return true;
        }
      }
    }
    return false;
  }

  /// Clears the selection.
  void clear({Pointer? pointer}) {
    for (final entity in entities.toList()) {
      remove(entity, pointer: pointer);
    }
  }

  /// Replace the current selection with a new selection.
  /// Returns true if the selection was successfuly replaced.
  bool replace(List<Entity> newSelection, {Pointer? pointer}) {
    final newSelectionResults = <Entity>[];
    for (final entity in newSelection) {
      final trait = entity.tryGet<SelectableTrait>();
      if (trait != null) {
        if (trait.selected == false) {
          final shouldGetSelected = trait.onSelected?.call(pointer);
          if (shouldGetSelected == true) {
            newSelectionResults.add(entity);
          }
        }
      }
    }

    // Deselect all.
    if (newSelectionResults.isNotEmpty) {
      clear(pointer: pointer);
    }

    // Select the new ones.
    for (final entity in newSelectionResults) {
      final trait = entity.tryGet<SelectableTrait>()!;
      trait.selected = true;
      entities.add(entity);
    }

    return newSelectionResults.isNotEmpty;
  }
}

class SelectableTrait extends Trait {
  /// Whether this node is currently selected.
  bool selected = false;

  /// Callback when this node is selected.
  final bool Function(Pointer? pointer)? onSelected;

  /// Callback when this node is deselected.
  final bool Function(Pointer? pointer)? onDeselected;

  SelectableTrait({this.onSelected, this.onDeselected});
}

/// A system to ensure SelectableTrait nodes also have a TappableTrait.
void ensureSelectableNodesAreTappable(Realm realm) {
  final toChange = <Entity>[];
  final query = realm.query(And([
    Has([SelectableTrait]),
    Without([TappableTrait])
  ]));
  for (final entity in query) {
    toChange.add(entity);
  }

  for (final entity in toChange) {
    entity.add(TappableTrait());
  }
}

/// A system that handles selection of nodes.
void selectableSystem(Realm realm) {
  final selection = realm.getResource<Selection>();
  final tappable = realm.checkOrRunSystem<TappableSystemResult>(tappableSystem);
  final input = realm.getResource<Input>();
  // When control is pressed, the selection is additive.
  // Otherwise, the selection is replaced.
  bool ctrlPressed = input.pressed(LogicalKeyboardKey.controlLeft) ||
      input.pressed(LogicalKeyboardKey.controlRight) ||
      input.pressed(LogicalKeyboardKey.metaLeft) ||
      input.pressed(LogicalKeyboardKey.metaRight);
  bool somethingGotSelected = false;
  for (final event in tappable.justReleased) {
    final entity = event.entity;
    final trait = entity.tryGet<SelectableTrait>();
    if (trait != null) {
      if (ctrlPressed) {
        if (trait.selected) {
          selection.remove(entity, pointer: event.pointer);
        } else {
          somethingGotSelected = selection.add(entity, pointer: event.pointer);
        }
      } else {
        somethingGotSelected =
            selection.replace([entity], pointer: event.pointer);
      }
    }
  }

  // Process the misses as deselection.
  if (ctrlPressed == false) {
    // Some pointers hit some nodes, but all of them rejected the selection,
    // or didn't have a SelectableTrait.
    if (somethingGotSelected == false &&
        (tappable.justReleased.isNotEmpty ||
            tappable.justReleasedMisses.isNotEmpty)) {
      for (final pointer in tappable.justReleasedMisses) {
        final shouldDeselect = selection.onGlobalDeslect?.call(pointer) ?? true;
        if (shouldDeselect == true) {
          selection.clear(pointer: pointer);
        }
      }
    }
  }
}
