import 'package:stater/stater/transaction/operation.dart';
import 'package:stater/stater/transaction/transaction.dart';

class TransactionManager {
  final List<Function()> _listeners = [];
  List<Transaction> _transactionQueue = List.unmodifiable(const []);

  void addTransaction(Transaction transaction) {
    _transactionQueue = List.unmodifiable([..._transactionQueue, transaction]);
    _notifyListeners();
  }

  void addTransactions(Iterable<Transaction> transactions) {
    _transactionQueue =
        List.unmodifiable([..._transactionQueue, ...transactions]);
    _notifyListeners();
  }

  void removeTransactionsById(Iterable<String> ids) {
    final idSet = ids.toSet();
    _transactionQueue = List.unmodifiable(_transactionQueue
        .where((transaction) => !idSet.contains(transaction.id)));
    _notifyListeners();
  }

  Map<String, dynamic>? applyTransactionsToEntity<ID extends Object?,
          T extends Map<String, dynamic>>(
      String collectionPath, ID documentId, T doc) {
    Map<String, dynamic>? nextDoc = doc;

    for (var transaction in _transactionQueue) {
      for (var operation in transaction.operations) {
        if (operation is OperationWithDocumentId &&
            operation.collectionPath == collectionPath &&
            operation.documentId == documentId) {
          switch (operation.changeType) {
            case OperationType.delete:
              nextDoc = null;
              break;
            case OperationType.set:
              nextDoc = {...(operation as OperationSet).data};
              break;
            case OperationType.update:
              if (nextDoc == null) {
                throw 'Trying to apply update operation to null document';
              } else {
                nextDoc = {...nextDoc, ...(operation as OperationUpdate).data};
              }
              break;
            default:
              throw 'Switch case of "${operation.changeType}" '
                  'is not implemented';
          }
        }
      }
    }

    return nextDoc;
  }

  Map<String, dynamic>? applyTransactionsToEntities<ID extends Object?,
          T extends Map<String, dynamic>>(
      String collectionPath, ID documentId, T doc) {
    throw 'applyTransactionsToEntities is not implemented';
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener.call();
    }
  }
}
