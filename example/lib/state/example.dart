import 'package:stater/stater.dart';

const localStorageCache = {
  'todos': {
    '1': {
      'name': 'Todo 1',
      'completed': false,
    }
  },
};

final pendingTransactions = [
  Transaction(
    operations: [
      UpdateOperation(
        collectionName: 'todos',
        documentId: '1',
        data: {'name': 'Todo 1.1'},
      ),
    ],
  ),
  Transaction(
    operations: [
      CreateOperation(
        collectionName: 'todos',
        documentId: '2',
        data: {'name': 'Todo 2', 'completed': false},
      ),
    ],
  ),
  Transaction(
    operations: [
      ServiceRequestOperation(
        serviceName: 'createManyTodos',
        params: ['randomId123', 'randomId124', 'randomId125'],
      ),
    ],
  ),
];
