import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/realm.dart';
import 'package:flutter/widgets.dart';

void longDownSystem(Realm realm) {
  final input = realm.getResource<Input>();
  final pointers = input.pointers();
  final downPointers = pointers.where((pointer) => pointer.state is PointerStateDown).toList();
  final longDownDuration = input.longDownDuration;

  // Check if pointer is down for more than a set time
  for (final pointer in downPointers) {
    if (pointer.state is PointerStateDown) {
      final downState = pointer.state as PointerStateDown;
      if (DateTime.now().difference(downState.timestamp) > longDownDuration) {
        pointer.pushState(PointerStateLongDown(downState.raw));

        if (input.debugMode) {
          debugPrint('${downState.debugName}:${pointer.id} -> LongDown');
        }
      }
    }
  }
}