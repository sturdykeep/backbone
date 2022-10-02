import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/extensions.dart';

class DraggablePointerPayload {
  final ANode initiator;
  final dynamic data;

  DraggablePointerPayload(this.initiator, this.data);
}

class DraggableTrait extends ATrait {
  final DraggablePointerPayload? Function(Pointer pointer, Vector2 offset)?
      onStart;
  final void Function(Pointer pointer)? onUpdate;
  final void Function(Pointer pointer, ANode?)? onEnd;

  DraggableTrait({this.onStart, this.onUpdate, this.onEnd});
}

class DragReceiverTrait extends ATrait {
  final void Function(Pointer pointer, DraggablePointerPayload? payload)
      onReceive;

  DragReceiverTrait({required this.onReceive});
}

void draggableSystem(Realm realm) {
  final query = realm.query(Has([DraggableTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  final dragStarts = input.justDragStartPointers();
  final dragUpdates = input.justDragUpdatePointers();
  final dragEnds = input.justDragEndPointers();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final draggable = node.get<DraggableTrait>();
    final tranform = node.tryGet<TransformTrait>();

    // Check drag starts
    for (var dragStart in dragStarts) {
      if (node.containsPoint(dragStart.worldPosition(realm.gameRef))) {
        if (draggable.onStart != null) {
          final offset = tranform != null
              ? dragStart.position - tranform.absolutePosition(node)
              : Vector2.zero();
          final payload = draggable.onStart!(dragStart, offset);
          dragStart.payload = payload;
        }
        dragStart.payload ??= DraggablePointerPayload(node, null);
      }
    }

    // Check drag updates
    for (var dragUpdate in dragUpdates) {
      if ((dragUpdate.payload as DraggablePointerPayload?)?.initiator == node) {
        if (draggable.onUpdate != null) {
          draggable.onUpdate!(dragUpdate);
        }
      }
    }

    // Check drag ends
    for (var dragEnd in dragEnds) {
      if ((dragEnd.payload as DraggablePointerPayload?)?.initiator == node) {
        if (draggable.onEnd != null) {
          draggable.onEnd!(dragEnd, null);
        }
      }
    }
  }
}

void dragReceiverSystem(Realm realm) {
  final query = realm.query(Has([DragReceiverTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  final dragEnds = input.justDragEndPointers();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final dragReceiver = node.get<DragReceiverTrait>();

    // Check drag ends
    for (var dragEnd in dragEnds) {
      if (node.containsPoint(dragEnd.worldPosition(realm.gameRef))) {
        final payload = dragEnd.payload as DraggablePointerPayload?;
        dragReceiver.onReceive(dragEnd, payload);
      }
    }
  }
}
