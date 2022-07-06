import 'package:stater/stater.dart';

Map<String, Map<String, dynamic>> generateSampleData() {
  return {
    'todos': {
      '1': {'name': 'Todo 1', 'completed': true}
    }
  };
}

List<Transaction> generateSampleTransactions() {
  return [
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
      id: 'updateTodo2',
      operations: [
        UpdateOperation(
          collectionName: 'todos',
          documentId: '2',
          data: {'name': 'Todo 2.1'},
        ),
      ],
    ),
    ExclusiveTransaction(
      id: 'createTodo3',
      operations: [
        CreateOperation(
          collectionName: 'todos',
          documentId: '3',
          data: {'name': 'Todo 3', 'completed': false},
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

final List<Map<String, Map<String, Map<String, dynamic>>>>
    expectedSampleSnapshots = [
  // before all transactions
  {
    'todos': {
      '1': {'name': 'Todo 1', 'completed': true},
    }
  },

  // after createTodo2
  {
    'todos': {
      '1': {'name': 'Todo 1', 'completed': true},
      '2': {'name': 'Todo 2', 'completed': false},
    }
  },

  // after updateTodo2
  {
    'todos': {
      '1': {'name': 'Todo 1', 'completed': true},
      '2': {'name': 'Todo 2.1', 'completed': false},
    }
  },

  // after createTodo3
  {
    'todos': {
      '1': {'name': 'Todo 1', 'completed': true},
      '2': {'name': 'Todo 2.1', 'completed': false},
      '3': {'name': 'Todo 3', 'completed': false},
    }
  },

  // after deleteTodo1
  {
    'todos': {
      '2': {'name': 'Todo 2.1', 'completed': false},
      '3': {'name': 'Todo 3', 'completed': false},
    }
  },
];

List<Map<String, dynamic>> generateSampleTransactionsAsJson() {
  return generateSampleTransactions()
      .map((transaction) => transaction.toMap())
      .toList();
}
