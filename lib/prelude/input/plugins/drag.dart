import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

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
  final query = realm.query(Has([DraggableTrait]));
  final queryLength = query.length;
  final input = realm.getResource<Input>();
  final dragStarts = input.justDragStartPointers();
  final dragUpdates = input.justDragUpdatePointers();
  for (var i = 0; i < queryLength; i++) {
    final node = query.elementAt(i);
    final draggable = node.get<DraggableTrait>();

    // Check drag starts
    for (var dragStart in dragStarts) {
      if (node.containsPoint(dragStart.position)) {
        if (draggable.onStart != null) {
          final payload = draggable.onStart!(dragStart);
          dragStart.payload = payload;
        } else {
          dragStart.payload = DraggablePointerPayload(node, null);
        }
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
      if (node.containsPoint(dragEnd.position)) {
        final payload = dragEnd.payload as DraggablePointerPayload?;
        if (dragReceiver.onReceive != null) {
          dragReceiver.onReceive!(dragEnd, payload);
          if (payload != null) {
            final draggable = payload.initiator.get<DraggableTrait>();
            if (draggable.onEnd != null) {
              draggable.onEnd!(dragEnd, node);
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
}
