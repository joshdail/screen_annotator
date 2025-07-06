import 'package:flutter/material.dart';
import 'pages/drawing_page.dart';

// TEST RUST BINDING
// native_bindings.dart
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

typedef NativeAddFunc = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef DartAddFunc = int Function(int, int);

class NativeBindings {
  late final ffi.DynamicLibrary _lib;

  NativeBindings() {
    _lib = Platform.isMacOS
        ? ffi.DynamicLibrary.open('libnative_rust.dylib')
        : throw UnsupportedError('This platform is not supported.');

    add = _lib
        .lookup<ffi.NativeFunction<NativeAddFunc>>('add_two_numbers')
        .asFunction();
  }

  late final DartAddFunc add;
}

void main() {
  // TEST RUST BINDINGS
  final bindings = NativeBindings();

  final result = bindings.add(40, 2);
  print("Rust says 40 + 2 = $result");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DrawingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
