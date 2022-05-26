import 'package:meta/meta.dart';
import 'package:stater/stater/transaction/operation.dart';
import 'package:stater/stater/transaction/transaction.dart';

class TransactionManager<T extends Transaction> {
  @protected
  final List<Function(TransactionManagerUpdate<T>)> listeners = [];

  @protected
  List<T> transactionQueue = List.unmodifiable(const []);

  void dispose() {
    listeners.clear();
  }

  void addTransaction(T transaction) {
    transactionQueue = List.unmodifiable([...transactionQueue, transaction]);
    _notifyListeners(TransactionManagerUpdateAdd([transaction]));
  }

  void addTransactions(Iterable<T> transactions) {
    transactionQueue =
        List.unmodifiable([...transactionQueue, ...transactions]);
    _notifyListeners(TransactionManagerUpdateAdd(transactions));
  }

  void removeTransactionsById(Iterable<String> ids) {
    final idSet = ids.toSet();

    final removed = <T>[];

    final nextQueue =
        List<T>.unmodifiable(transactionQueue.where((transaction) {
      if (idSet.contains(transaction.id)) {
        removed.add(transaction);
        return false;
      }
      return true;
    }));

    if (removed.isNotEmpty) {
      transactionQueue = nextQueue;
      _notifyListeners(TransactionManagerUpdateRemove(removed));
    }
  }

  Map<String, dynamic>? applyTransactionsToEntity<ID extends Object?,
          T extends Map<String, dynamic>>(
      String collectionPath, ID documentId, T doc) {
    Map<String, dynamic>? nextDoc = doc;

    for (var transaction in transactionQueue) {
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
              throw 'applyTransactionsToEntity: switch case of "${operation.changeType}" '
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
    throw 'TransactionManager.applyTransactionsToEntities is not implemented';
  }

  void _notifyListeners(TransactionManagerUpdate<T> update) {
    for (var listener in listeners) {
      listener.call(update);
    }
  }
}

abstract class TransactionManagerUpdate<T> {}

class TransactionManagerUpdateAdd<T extends Transaction>
    extends TransactionManagerUpdate<T> {
  final Iterable<T> added;

  TransactionManagerUpdateAdd(this.added);
}

class TransactionManagerUpdateRemove<T extends Transaction>
    extends TransactionManagerUpdate<T> {
  final Iterable<T> removed;

  TransactionManagerUpdateRemove(this.removed);
}
