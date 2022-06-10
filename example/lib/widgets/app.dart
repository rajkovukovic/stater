import 'package:flutter/material.dart';
import 'package:stater_example/state/state.dart';
import 'package:stater_example/widgets/home_screen.dart';
import 'package:stater_example/widgets/todos_screen_no_converters.dart';
import 'package:stater_example/widgets/todos_screen_with_converters.dart';

class Routes {
  static String home = 'home';
  static String withConverters = 'withConverters';
  static String noConverters = 'noConverters';
  static String splitScreen = 'splitScreen';
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.home,
        routes: {
          Routes.home: (context) => const HomeScreen(),
          Routes.withConverters: (context) =>
              TodosScreenWithConverters(storage: state),
          Routes.noConverters: (context) =>
              TodosScreenNoConverters(storage: state),
          Routes.splitScreen: (context) => Row(children: [
                Expanded(child: TodosScreenWithConverters(storage: state)),
                Expanded(child: TodosScreenNoConverters(storage: state)),
              ]),
        },
      ),
    );
  }
}
