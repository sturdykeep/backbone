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
  final DraggablePointerPayload? Function(Pointer pointer)? onStart;
  final void Function(Pointer pointer)? onUpdate;
  final void Function(Pointer pointer, ANode?)? onEnd;

  DraggableTrait({this.onStart, this.onUpdate, this.onEnd});
}

class DragReceiverTrait extends ATrait {
  final void Function(Pointer pointer, DraggablePointerPayload? payload)?
      onReceive;

  DragReceiverTrait({this.onReceive});
}

void draggableSystem(Realm realm) {
  final query = realm.query(Has([DraggableTrait, TransformTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final draggable = node.get<DraggableTrait>();
    final transform = node.get<TransformTrait>();

    // Check drag starts
    final dragStarts = input.justDragStartPointers();
    for (var dragStart in dragStarts) {
      if (transform.rect.containsPoint(dragStart.position)) {
        if (draggable.onStart != null) {
          final payload = draggable.onStart!(dragStart);
          dragStart.payload = payload;
        }
      }
    }

    // Check drag updates
    final dragUpdates = input.justDragUpdatePointers();
    for (var dragUpdate in dragUpdates) {
      if (dragUpdate.payload == node) {
        if (draggable.onUpdate != null) {
          draggable.onUpdate!(dragUpdate);
        }
      }
    }
  }
}

void dragReceiverSystem(Realm realm) {
  final query = realm.query(Has([DragReceiverTrait, TransformTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final dragReceiver = node.get<DragReceiverTrait>();
    final transform = node.get<TransformTrait>();

    // Check drag ends
    final dragEnds = input.justDragEndPointers();
    for (var dragEnd in dragEnds) {
      if (transform.rect.containsPoint(dragEnd.position)) {
        final payload = dragEnd.payload as DraggablePointerPayload?;
        if (dragReceiver.onReceive != null) {
          dragReceiver.onReceive!(dragEnd, payload);
          if (payload != null) {
            final draggable = payload.initiator.get<DraggableTrait>();
            if (draggable.onEnd != null) {
              draggable.onEnd!(dragEnd, node);
            }
          }
        }
      } else {
        // Just end the drag for the draggable
        final payload = dragEnd.payload as DraggablePointerPayload?;
        if (payload != null) {
          final draggable = payload.initiator.get<DraggableTrait>();
          if (draggable.onEnd != null) {
            draggable.onEnd!(dragEnd, null);
          }
        }
      }
    }
  }
}
