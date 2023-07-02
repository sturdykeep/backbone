import 'package:backbone/src/bridge_generated.dart';

/// Represents the external library for backbone
///
/// Will be a DynamicLibrary for dart:io or WasmModule for dart:html
typedef ExternalLibrary = Object;

Backbone createWrapperImpl(ExternalLibrary lib) =>
    throw UnimplementedError();
