import 'package:backbone/src/bridge_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

typedef ExternalLibrary = WasmModule;

Backbone createWrapperImpl(ExternalLibrary module) =>
    BackboneImpl.wasm(module);
