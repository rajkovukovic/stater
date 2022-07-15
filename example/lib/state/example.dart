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
    // localStorageInProgress
    id: 'createTodo1',
    operations: [
      UpdateOperation(
        collectionName: 'todos',
        documentId: '1',
        data: {'name': 'Todo 1'},
      ),
    ],
  ),
  Transaction(
    // restInProgress
    id: 'updateTodo1',
    operations: [
      UpdateOperation(
        collectionName: 'todos',
        documentId: '1',
        data: {'name': 'Todo 1.1'},
      ),
    ],
  ),
  Transaction(
    id: 'createTodo2',
    operations: [
      CreateOperation(
        collectionName: 'todos',
        documentId: '2',
        data: {'name': 'Todo 2', 'completed': false},
      ),
    ],
  ),
  Transaction(
    id: 'deleteTodo1',
    operations: [
      DeleteOperation(
        collectionName: 'todos',
        documentId: '1',
      ),
    ],
  ),
  // Transaction(
  //   id: 'create3todos',
  //   operations: [
  //     ServiceRequestOperation(
  //       serviceName: 'createManyTodos',
  //       params: ['randomId123', 'randomId124', 'randomId125'],
  //     ),
  //   ],
  // ),
];

/// Story: imagine a getTodos request arrives while the client's transaction
/// queue is in the middle of processing transactions.
///
/// In this example, when the getTodos request arrives,
/// localStorage is in the middle of processing of 'createTodo1' transaction
/// and rest is in the middle of processing 'updateTodo1' transaction
getTodosWhileWriteTransactionsAreBeingProcessed() async {
  // make sure localStorage can not perform transactions that are not processed
  // by REST at the moment of this get request arrived
  lockTransactionForLocalStorage('updateTodo1');

  // fire a REST read request even if there is a REST write transaction
  // being currently processed
  final todosFromRest = await getTodosFromRest();

  // write todos fetched via REST to local storage before performing 'updateTodo1'
  // transaction on localStorage
  insertLocalStorageTransactionIntoQueue(
    writeTodosFromRestTransaction(todosFromRest),
    before: 'updateTodo1',
  );

  // clone localStorage cache to inMemoryCache
  // final inMemoryCache = await localStorageCache.toInMemoryCache();

  // add todosFromRest to inMemoryCache
  // inMemoryCache.add('todos', todosFromRest);

  // allow localStorage to continue processing transactions
  unlockTransactionForLocalStorage('updateTodo1');

  // apply all transactions from the queue, from 'updateTodo1' onwards,
  // to todosFromRest
  // to make sure data fetched via rest has latest changes that are still
  // in the client's queue
  final updatedTodosFromRest = await applyTransactionsToData(
      getTransactions(from: 'createTodo2'), todosFromRest);

  return updatedTodosFromRest;
}

/// dummy functions
///
///
///
///
///
///
getTransactions({required String from}) {}

applyTransactionsToData(transactions, todosFromRest) {}

void unlockTransactionForLocalStorage(String s) {}

writeTodosFromRestTransaction(todosFromRest) {}

void insertLocalStorageTransactionIntoQueue(writeTodosFromRestTransaction,
    {required String before}) {}

getTodosFromRest() {}

void lockTransactionForLocalStorage(String s) {}
