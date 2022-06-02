import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';

import 'cascade_storage_screen.dart';

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

final stater = CascadeStorage(
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

// final stater = GetStorageStorage(
//   GetStorageDelegate(
//     id: 'get-storage',
//     storagePrefix: 'DB',
//   ),
// );

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CascadeStorageScreen(storage: stater),
    );
  }
}
