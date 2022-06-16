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
    Transaction(operations: [
      UpdateOperation(
          collectionName: 'todos', documentId: '1', data: {'name': 'Todo 1.1'}),
    ]),
    Transaction(operations: [
      CreateOperation(
          collectionName: 'todos', documentId: '2', data: {'name': 'Todo 2'}),
    ]),
  ];
}
