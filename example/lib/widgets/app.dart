import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';
import 'package:stater_example/widgets/home_screen.dart';
import 'package:stater_example/widgets/todos_screen_no_converters.dart';
import 'package:stater_example/widgets/todos_screen_with_converters.dart';

bool doesTodoMatchQuery(Todo todo, Query query) {
  if (query.compareOperations.isEmpty) {
    return true;
  } else if (query.compareOperations.length == 1 &&
      query.compareOperations.first.compareOperator ==
          CompareOperator.isEqualTo &&
      query.compareOperations.first.field == 'completed') {
    return todo.completed == query.compareOperations.first.valueToCompareTo;
  } else {
    throw 'Can only query a map by "completed" field for equality';
  }
}

final restDelegate = RestDelegate(
  id: 'rest-server-mongodb',
  endpoint: 'http://localhost:3030',
  // doesMatchQuery: doesTodoMatchQuery,
);

final getStorageDelegate = GetStorageDelegate(
  id: 'get-storage',
  storagePrefix: 'DB',
  // doesMatchQuery: doesTodoMatchQuery,
);

const _useLocalStorageOnly = !kIsWeb;

final stater = _useLocalStorageOnly
    ? CascadeStorage(
        primaryDelegate: getStorageDelegate,
        cachingDelegates: [],
        transactionStoringDelegate: TransactionStoringDelegate.fromDelegate(
          delegate: getStorageDelegate,
          collectionName: 'uncommitted',
          transactionsKey: 'transactions',
          transactionsStateKey: 'processedTransactions',
        ))
    : CascadeStorage(
        primaryDelegate: restDelegate,
        cachingDelegates: [
          getStorageDelegate,
        ],
        transactionStoringDelegate: TransactionStoringDelegate.fromDelegate(
          delegate: getStorageDelegate,
          collectionName: 'uncommitted',
          transactionsKey: 'transactions',
          transactionsStateKey: 'processedTransactions',
        ));

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
              TodosScreenWithConverters(storage: stater),
          Routes.noConverters: (context) =>
              TodosScreenNoConverters(storage: stater),
          Routes.splitScreen: (context) => Row(children: [
                Expanded(child: TodosScreenWithConverters(storage: stater)),
                Expanded(child: TodosScreenNoConverters(storage: stater)),
              ]),
        },
      ),
    );
  }
}
