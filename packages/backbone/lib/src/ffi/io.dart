import 'dart:ffi';

import 'package:backbone/src/bridge_generated.dart';

typedef ExternalLibrary = DynamicLibrary;

Backbone createWrapperImpl(ExternalLibrary dylib) =>
    BackboneImpl(dylib);
