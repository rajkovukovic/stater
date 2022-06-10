import 'package:stater/stater.dart';
import 'package:stater_example/state/does_todo_match_query.dart';

final restDelegate = RestDelegate(
  id: 'rest-server-mongodb',
  endpoint: 'http://localhost:3030',
);

final localStorageDelegate = GetStorageDelegate(
  id: 'get-storage',
  storagePrefix: 'DB',
);

const queryMatcher = JsonQueryMatcher({
  'todos': doesTodoMatchQuery,
});

final state = CascadeStorage(
  primaryDelegate: restDelegate,
  cachingDelegates: [
    localStorageDelegate,
  ],
  transactionStoringDelegate: TransactionStoringDelegate.fromDelegate(
    delegate: localStorageDelegate,
    collectionName: 'uncommitted',
    transactionsKey: 'transactions',
    transactionsStateKey: 'processedTransactions',
  ),
  queryMatcher: queryMatcher,
);

// final localData = {'photos': {}};

// final queue = [
//   Transaction(
//     operations: [
//       ServiceRequest(
//         data: {'filePath': filePath, 'documentId': 'photo_id_1'},
//         serviceName: 'uploadPhotos',
//       ),
//     ],
//   )
// ];

// final filePath = {};

// final a =
//     state.request('uploadPhotos', {'filePath': filePath, 'documentId': 'uuid'});

// final newTodoFuture = state.collection('todos').add({'name': 'Buy Milk'});

// final existingTodoFuture = state.collection('todos').doc('id_todo_123').get();

// final updateTodoFuture =
//     state.collection('todos').doc('id_todo_123').update({'name': 'novo ime'});

// final deleteTodoFuture = state.collection('todos').doc('id_todo_123').delete();

// final completedOnlyTodos = state
//     .collection('todos')
//     .where('completed', CompareOperator.isEqualTo, true)
//     .get();

// // TODO: rename to service request
// final serviceRequest1 = state.request(
//   'createTodoAddAssignToUser',
//   {'name': 'New Todo', 'userId': 'id_user_1'},
// );

// final serviceRequest2 = state.request(
//   'changeTodoOwner',
//   {'todoId': 'id_todo_123', 'userId': 'id_user_1'},
// );
