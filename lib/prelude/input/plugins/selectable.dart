import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

/// Resource that holds a reference to [SelectableTrait] nodes, which
/// are currently selected.
class Selection<T extends FlameGame> {
  bool Function(Pointer pointer)? onGlobalDeslect;

  /// The currently selected nodes.
  final List<ANode<T>> nodes = [];

  /// Adds a node to the selection.
  /// Returns true, if the node was successfuly selected.
  bool add(ANode<T> node, {Pointer? pointer}) {
    final trait = node.tryGet<SelectableTrait<T>>();
    if (trait != null) {
      if (trait.selected == false) {
        final shouldGetSelected = trait.onSelected?.call(pointer);
        if (shouldGetSelected == true) {
          trait.selected = true;
          nodes.add(node);
          return true;
        }
      }
    }
    return false;
  }

  /// Removes a node from the selection.
  /// Returns true if the node was removed, false otherwise.
  /// If the node was not in the selection, it will return false.
  bool remove(ANode node, {Pointer? pointer}) {
    final trait = node.tryGet<SelectableTrait<T>>();
    if (trait != null) {
      if (trait.selected == true) {
        final shouldGetDeselected = trait.onDeselected?.call(pointer);
        if (shouldGetDeselected == true) {
          trait.selected = false;
          nodes.remove(node);
          return true;
        }
      }
    }
    return false;
  }

  /// Clears the selection.
  void clear({Pointer? pointer}) {
    for (final node in nodes.toList()) {
      remove(node, pointer: pointer);
    }
  }

  /// Replace the current selection with a new selection.
  /// Returns true if the selection was successfuly replaced.
  bool replace(List<ANode<T>> newSelection, {Pointer? pointer}) {
    final newSelectionResults = <ANode<T>>[];
    for (final node in newSelection) {
      final trait = node.tryGet<SelectableTrait<T>>();
      if (trait != null) {
        if (trait.selected == false) {
          final shouldGetSelected = trait.onSelected?.call(pointer);
          if (shouldGetSelected == true) {
            newSelectionResults.add(node);
          }
        }
      }
    }

    // Deselect all nodes.
    if (newSelectionResults.isNotEmpty) {
      clear(pointer: pointer);
    }

    // Select the new nodes.
    for (final node in newSelectionResults) {
      final trait = node.tryGet<SelectableTrait<T>>()!;
      trait.selected = true;
      nodes.add(node);
    }

    return newSelectionResults.isNotEmpty;
  }
}

class SelectableTrait<T extends FlameGame> extends ATrait<T> {
  /// Whether this node is currently selected.
  bool selected = false;

  /// Callback when this node is selected.
  final bool Function(Pointer? pointer)? onSelected;

  /// Callback when this node is deselected.
  final bool Function(Pointer? pointer)? onDeselected;

  SelectableTrait({this.onSelected, this.onDeselected});
}

/// A system to ensure SelectableTrait nodes also have a TappableTrait.
void ensureSelectableNodesAreTappable<T extends FlameGame>(Realm<T> realm) {
  final toChange = <ANode<T>>[];
  final query = realm.query(And([
    Has([SelectableTrait]),
    Without([TappableTrait])
  ]));
  for (final node in query) {
    toChange.add(node);
  }

  for (final node in toChange) {
    node.addTrait(TappableTrait());
  }
}

/// A system that handles selection of nodes.
void selectableSystem<T extends FlameGame>(Realm<T> realm) {
  final selection = realm.getResource<Selection<T>>();
  final tappable =
      realm.checkOrRunSystem<TappableSystemResult<T>>(tappableSystem);
  final input = realm.getResource<Input>();
  // When control is pressed, the selection is additive.
  // Otherwise, the selection is replaced.
  bool ctrlPressed = input.pressed(LogicalKeyboardKey.controlLeft) ||
      input.pressed(LogicalKeyboardKey.controlRight) ||
      input.pressed(LogicalKeyboardKey.metaLeft) ||
      input.pressed(LogicalKeyboardKey.metaRight);
  bool somethingGotSelected = false;
  for (final event in tappable.justReleased) {
    final node = event.node;
    final trait = node.tryGet<SelectableTrait<T>>();
    if (trait != null) {
      if (ctrlPressed) {
        if (trait.selected) {
          selection.remove(node, pointer: event.pointer);
        } else {
          somethingGotSelected = selection.add(node, pointer: event.pointer);
        }
      } else {
        somethingGotSelected =
            selection.replace([node], pointer: event.pointer);
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
