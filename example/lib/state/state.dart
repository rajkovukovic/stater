import 'package:stater/stater.dart';
import 'package:stater_example/state/does_todo_match_query.dart';
import 'package:uuid/uuid.dart';

final restDelegate = RestDelegate(
  id: 'rest-server-mongodb',
  endpoint: 'http://192.168.0.13:3030',
);

final localStorageDelegate = GetStorageDelegate(
  id: 'get-storage',
  storagePrefix: 'DB',
);

const queryMatcher = JsonQueryMatcher({
  'todos': doesTodoMatchQuery,
});

ServiceRequestProcessor serviceRequestProcessorFactory(Storage storage) {
  return (String serviceName, dynamic params) async {
    switch (serviceName) {
      case 'createManyTodos':
        final int createCount = params;

        final todosCollection = storage.collection('todos');

        final existingTodos = (await todosCollection.get()).docs;

        final existingNames = existingTodos.fold<Set<String>>(
            {},
            (acc, doc) => acc
              ..add((doc.data() as Map<String, dynamic>)['name']
                  .replaceAll(RegExp(r"\s+"), "")));

        int nextTodoNumber = 1;

        for (var i = 0; i < createCount; i++) {
          while (existingNames.contains('todo$nextTodoNumber')) {
            nextTodoNumber++;
          }

          final todo = {'name': 'Todo $nextTodoNumber', 'completed': false};
          await todosCollection.add(
            todo,
            documentId: const Uuid().v4(),
          );

          nextTodoNumber++;
        }
        break;
      default:
        throw 'RestDelegate does not support serviceRequest "$serviceName"';
    }
  };
}

final state = CascadeStorage(
  primaryDelegate: restDelegate,
  cachingDelegates: [
    localStorageDelegate,
  ],
  transactionStoringDelegate: TransactionStorer.fromDelegate(
    storage: localStorageDelegate,
    collectionName: 'uncommitted',
    transactionsKey: 'transactions',
    transactionsStateKey: 'processedTransactions',
  ),
  serviceRequestProcessorFactory: serviceRequestProcessorFactory,
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

// final filePath = '/Users/me/photo.jpg';

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
