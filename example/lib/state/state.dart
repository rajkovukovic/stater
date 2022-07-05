import 'package:stater/stater.dart';
import 'package:stater_example/state/services/create_many_todos.dart';

// final restStorage = RestStorage(
//   id: 'rest-server',
//   endpoint: 'http://192.168.0.11:54123/api',
// );

// final localStorage = LocalStorage(
//   id: 'get-storage',
//   storagePrefix: 'DB',
// );

// const queryMatcher = JsonQueryMatcher({
//   'todos': doesTodoMatchQuery,
// });

ServiceProcessor serviceProcessorFactory(Storage storage) {
  return (String serviceName, dynamic params) async {
    switch (serviceName) {
      case 'createManyTodos':
        return createManyTodos(storage, params);
      default:
        throw 'Service "$serviceName" is not supported in offline mode.\n'
            'You can implement it in Storage.serviceProcessorFactory.';
    }
  };
}

final state = Storage(InMemoryAdapter({}));

// final state = CascadeStorage(
//   primaryStorage: restStorage,
//   cachingStorages: [localStorage],
//   transactionStoringDelegate: TransactionStorer.fromStorage(localStorage),
//   serviceProcessorFactory: serviceProcessorFactory,
//   queryMatcher: queryMatcher,
// );

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
