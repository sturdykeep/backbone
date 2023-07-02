import 'package:backbone/backbone.dart';
import 'ffi/stub.dart'
    if (dart.library.io) 'ffi/io.dart'
    if (dart.library.html) 'ffi/web.dart';

Backbone createLib() => createWrapper(createLibraryImpl());
