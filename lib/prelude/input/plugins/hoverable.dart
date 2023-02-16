import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

class HoverableTrait extends Trait {
  final void Function(Pointer pointer)? onHoverEnter;
  final void Function(Pointer pointer)? onHoverExit;
  final void Function(Pointer pointer)? onHoverMove;

  Set<Pointer> pointers = {};

  HoverableTrait({this.onHoverEnter, this.onHoverExit, this.onHoverMove});
}

void hoverableSystem(Realm realm) {
  final query = realm.query(Has([HoverableTrait]));
  final input = realm.getResource<Input>();
  final hoverEnters = input.justHoverEnterPointers();
  final hovers = input.justHoverPointers();
  final hoverLeaves = input.justHoverLeavePointers();
  final pendingHovers = input.pendingHoverPointers();

  // Debug all pointers and their states
  // String stateString = '------------------\n';
  // for (final pointer in input.pointers()) {
  //   stateString += 'Pointer ${pointer.id} has state: ${pointer.state}\n';
  // }
  // debugPrint(stateString);

  final foundHoverEnters = [];
  final foundHoverExits = [];
  final foundHoverMoves = [];

  for (final entity in query) {
    final hoverable = entity.get<HoverableTrait>();
    final transformTrait = entity.get<TransformTrait>();

    // Check hover enters
    for (var hoverEnter in hoverEnters) {
      if (transformTrait
          .containsPoint(hoverEnter.worldPosition(realm.gameRef))) {
        hoverable.pointers.add(hoverEnter);
        foundHoverEnters.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': hoverEnter,
        });
      }
    }

    // Check hover moves which aren't in the pointer list
    for (var hover in hovers) {
      if (transformTrait.containsPoint(hover.worldPosition(realm.gameRef)) &&
          hoverable.pointers.contains(hover) == false) {
        hoverable.pointers.add(hover);
        foundHoverEnters.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': hover,
        });
      }
    }

    // Check hover leaves
    for (var hoverLeave in hoverLeaves) {
      if (hoverable.pointers.contains(hoverLeave)) {
        hoverable.pointers.remove(hoverLeave);
        foundHoverExits.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': hoverLeave,
        });
      }
    }

    // Check the entered pointer list
    // 1. Check if the pointer is still in the rect and has hover move state
    // 2. Check if the pointer not being in the hover mode anymore
    final pointers = hoverable.pointers.toList();
    for (var pointer in pointers) {
      if (transformTrait.containsPoint(pointer.worldPosition(realm.gameRef)) &&
          (pointer.isPointerAdded || pointer.isHovering)) {
        foundHoverMoves.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': pointer,
        });
      } else {
        hoverable.pointers.remove(pointer);
        foundHoverExits.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': pointer,
        });
      }
    }

    // Check pending hovers for pointers not yet in the list
    for (var pendingHover in pendingHovers) {
      if (transformTrait
              .containsPoint(pendingHover.worldPosition(realm.gameRef)) &&
          hoverable.pointers.contains(pendingHover) == false) {
        hoverable.pointers.add(pendingHover);
        foundHoverEnters.add({
          'entity': entity,
          'hoverable': hoverable,
          'pointer': pendingHover,
        });
      }
    }
  }

  // Call the callbacks based on the node's priority
  final foundHoverEntersSorted = (foundHoverEnters.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (final found in foundHoverEntersSorted) {
    final hoverable = found["hoverable"];
    hoverable.onHoverEnter?.call(found["pointer"]);
  }

  final foundHoverExitsSorted = (foundHoverExits.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (final found in foundHoverExitsSorted) {
    final hoverable = found["hoverable"];
    hoverable.onHoverExit?.call(found["pointer"]);
  }

  final foundHoverMovesSorted = (foundHoverMoves.toList()
        ..sort((a, b) => a["node"].compareToOnPriority(b["node"])))
      .reversed;
  for (final found in foundHoverMovesSorted) {
    final hoverable = found["hoverable"];
    hoverable.onHoverMove?.call(found["pointer"]);
  }
}
