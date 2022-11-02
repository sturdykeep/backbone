import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flutter/services.dart';

/// Resource that holds a reference to [SelectableTrait] nodes, which
/// are currently selected.
class Selection {
  /// The currently selected nodes.
  final List<ANode> nodes = [];

  /// Adds a node to the selection.
  void add(ANode node, {Pointer? pointer}) {
    final trait = node.tryGet<SelectableTrait>();
    if (trait != null) {
      if (trait.selected == false) {
        final shouldGetSelected = trait.onSelected?.call(pointer);
        if (shouldGetSelected == true) {
          trait.selected = true;
          nodes.add(node);
        }
      }
    }
  }

  /// Removes a node from the selection.
  /// Returns true if the node was removed, false otherwise.
  /// If the node was not in the selection, it will return false.
  bool remove(ANode node, {Pointer? pointer}) {
    final trait = node.tryGet<SelectableTrait>();
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
  void replace(List<ANode> newSelection) {
    clear();
    for (final node in newSelection) {
      add(node);
    }
  }
}

class SelectableTrait extends ATrait {
  /// Whether this node is currently selected.
  bool selected = false;

  /// Callback when this node is selected.
  final bool Function(Pointer? pointer)? onSelected;

  /// Callback when this node is deselected.
  final bool Function(Pointer? pointer)? onDeselected;

  SelectableTrait({this.onSelected, this.onDeselected});
}

/// A system that handles selection of nodes.
void selectableSystem(Realm realm) {
  final selection = realm.getResource<Selection>();
  final tappable = realm.runDependency<TappableSystemResult>(tappableSystem);
  final input = realm.getResource<Input>();
  // When control is pressed, the selection is additive.
  // Otherwise, the selection is replaced.
  bool ctrlPressed = input.pressed(LogicalKeyboardKey.controlLeft) ||
      input.pressed(LogicalKeyboardKey.controlRight) ||
      input.pressed(LogicalKeyboardKey.metaLeft) ||
      input.pressed(LogicalKeyboardKey.metaRight);
  for (final event in tappable.justReleased) {
    if (event.pointer.handled == false) {
      final node = event.node;
      final trait = node.tryGet<SelectableTrait>();
      if (trait != null) {
        if (ctrlPressed) {
          if (trait.selected) {
            selection.remove(node);
          } else {
            selection.add(node);
          }
        } else {
          selection.replace([node]);
        }
        event.pointer.handled = true;
      }
    }
  }

  // Process the misses as deselection.
  if (ctrlPressed == false) {
    for (final pointer in tappable.justReleasedMisses) {
      // TODO: This needs to be run after the rest of the systems
      // and needs to check if the pointer was handled. For example,
      // if one wants to execute an action with selected nodes when
      // a user clicks on an empty space (e.g. RTS right-click to move).

      // Deselct all nodes if the user clicks on an empty space.
      if (pointer.handled == false) {
        selection.clear();
        pointer.handled = true;
      }
    }
  }
}
