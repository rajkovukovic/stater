import 'package:flutter/material.dart';
import 'package:stater/stater/stater.dart';
import 'package:stater/widgets/cascade_storage_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CascadeStorageScreen(adapter: stater),
    );
  }
}
