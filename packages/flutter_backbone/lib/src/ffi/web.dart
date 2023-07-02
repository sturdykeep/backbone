import 'package:backbone/backbone.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

WasmModule createLibraryImpl() {
  // TODO add web support. See:
  // https://github.com/fzyzcjy/flutter_rust_bridge/blob/master/frb_example/with_flutter/lib/ffi.web.dart
  throw UnsupportedError('Web support is not provided yet.');
}
