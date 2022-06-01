library stater;

import 'package:stater/custom/get_storage_storage.dart';
import 'package:stater/custom/rest_storage.dart';
import 'package:stater/stater/cascade_storage/cascade_storage.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/transaction/transaction_storing_delegate.dart';

bool doesTodoMatchQuery(Object? element, Query query) {
  if (query.compareOperations.isEmpty) {
    return true;
  } else if (query.compareOperations.length == 1 &&
      query.compareOperations.first.compareOperator ==
          CompareOperator.isEqualTo &&
      query.compareOperations.first.field == 'completed' &&
      element is Map) {
    return (element['completed'] ?? false) ==
        query.compareOperations.first.valueToCompareTo;
  } else {
    throw 'Can only query a map by "completed" field for equality';
  }
}

final restDelegate = RestDelegate(
  id: 'rest-server-mongodb',
  endpoint: 'http://localhost:3030',
  doesMatchQuery: doesTodoMatchQuery,
);

final getStorageDelegate = GetStorageDelegate(
  id: 'get-storage',
  storagePrefix: 'DB',
  doesMatchQuery: doesTodoMatchQuery,
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
