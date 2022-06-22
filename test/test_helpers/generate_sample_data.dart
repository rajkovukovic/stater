import 'package:stater/stater.dart';

Map<String, Map<String, dynamic>> generateSampleData() {
  return {
    'todos': {
      '1': {
        'name': 'Todo 1',
      }
    }
  };
}

List<Transaction> generateSampleTransactions() {
  return [
    ExclusiveTransaction(
      id: 'createTodo1',
      operations: [
        UpdateOperation(
          collectionName: 'todos',
          documentId: '1',
          data: {'name': 'Todo 1'},
        ),
      ],
    ),
    ExclusiveTransaction(
      id: 'updateTodo1',
      operations: [
        UpdateOperation(
          collectionName: 'todos',
          documentId: '1',
          data: {'name': 'Todo 1.1'},
        ),
      ],
    ),
    ExclusiveTransaction(
      id: 'createTodo2',
      operations: [
        CreateOperation(
          collectionName: 'todos',
          documentId: '2',
          data: {'name': 'Todo 2', 'completed': false},
        ),
      ],
    ),
    ExclusiveTransaction(
      id: 'deleteTodo1',
      operations: [
        DeleteOperation(
          collectionName: 'todos',
          documentId: '1',
        ),
      ],
    ),
    // ExclusiveTransaction(
    //   id: 'create3todos',
    //   operations: [
    //     ServiceRequestOperation(
    //       serviceName: 'createManyTodos',
    //       params: ['randomId123', 'randomId124', 'randomId125'],
    //     ),
    //   ],
    // ),
  ];
}

List<Map<String, dynamic>> generateSampleTransactionsAsJson() {
  return generateSampleTransactions()
      .map((transaction) => transaction.toMap())
      .toList();
}
