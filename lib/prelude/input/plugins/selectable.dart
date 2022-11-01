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
  void add(ANode node) {
    final trait = node.tryGet<SelectableTrait>();
    if (trait != null) {
      if (trait.selected == false && trait.selectable == true) {
        trait.selected = true;
        trait.onSelected?.call();
        nodes.add(node);
      }
    }
  }

  /// Removes a node from the selection.
  /// Returns true if the node was removed, false otherwise.
  /// If the node was not in the selection, it will return false.
  bool remove(ANode node) {
    final trait = node.tryGet<SelectableTrait>();
    if (trait != null) {
      if (trait.selected == true) {
        trait.selected = false;
        trait.onDeselected?.call();
        return nodes.remove(node);
      }
    }
    return false;
  }

  /// Clears the selection.
  void clear() {
    for (final node in nodes) {
      final trait = node.tryGet<SelectableTrait>();
      if (trait != null) {
        trait.selected = false;
        trait.onDeselected?.call();
      }
    }
    nodes.clear();
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

  /// Whether this node is currently selectable.
  bool selectable = true;

  /// Callback when this node is selected.
  final void Function()? onSelected;

  /// Callback when this node is deselected.
  final void Function()? onDeselected;

  SelectableTrait({this.onSelected, this.onDeselected});
}

/// A system that handles selection of nodes.
void selectableSystem(Realm realm) {
  final selection = realm.getResource<Selection>();
  final tappable = realm.runDependency<TappableSystemResult>(tappableSystem);
  final input = realm.getResource<Input>();
  // When control is pressed, the selection is additive.
  // Otherwise, the selection is replaced.
  bool ctrlPressed = input.pressed(LogicalKeyboardKey.controlLeft);
  for (final event in tappable.justReleased) {
    if (event.pointer.handled == false) {
      final node = event.node;
      final trait = node.tryGet<SelectableTrait>();
      if (trait != null) {
        if (trait.selectable == true) {
          if (ctrlPressed == true) {
            if (trait.selected == true) {
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
  }

  // Process the misses as deselection.
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
