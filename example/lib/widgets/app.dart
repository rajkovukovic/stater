import 'package:flutter/material.dart';
import 'package:stater_example/state.dart';

import 'cascade_storage_screen.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CascadeStorageScreen(storage: state),
    );
  }
}
