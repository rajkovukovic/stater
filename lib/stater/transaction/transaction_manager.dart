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

  List<T> getTransactionQueue() => transactionQueue;

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

  dynamic applyTransactionsToEntity<ID extends Object?>({
    required String collectionPath,
    required ID documentId,
    required Map<String, dynamic>? data,
    Iterable<T>? useThisTransactions,
  }) {
    Map<String, dynamic>? nextData = data;

    for (var transaction in useThisTransactions ?? transactionQueue) {
      for (var operation in transaction.operations) {
        if (operation is OperationWithDocumentId &&
            operation.collectionPath == collectionPath &&
            operation.documentId == documentId) {
          switch (operation.changeType) {
            case OperationType.delete:
              nextData = null;
              break;
            case OperationType.set:
              nextData = {...(operation as OperationSet).data};
              break;
            case OperationType.update:
              if (nextData == null) {
                throw 'Trying to apply update operation to null document';
              } else {
                nextData = {
                  ...nextData,
                  ...(operation as OperationUpdate).data
                };
              }
              break;
            default:
              throw 'applyTransactionsToEntity: switch case of "${operation.changeType}" '
                  'is not implemented';
          }
        }
      }
    }

    return nextData;
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
