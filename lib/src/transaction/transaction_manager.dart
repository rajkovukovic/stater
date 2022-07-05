import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:stater/src/transaction/transaction.dart';

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
    print('\naddTransaction');
    try {
      print(jsonEncode(transaction.toMap()));
    } catch (_) {
      print(
          '${transaction.runtimeType} (${transaction.operations.first.runtimeType})');
    }
    transactionQueue = List.unmodifiable([...transactionQueue, transaction]);
    notifyListeners(TransactionManagerUpdateAdd([transaction]));
  }

  void addTransactions(Iterable<T> transactions) {
    print('\naddTransactionS');
    print(jsonEncode(
        transactions.map((transaction) => transaction.toMap()).toList()));
    transactionQueue =
        List.unmodifiable([...transactionQueue, ...transactions]);
    notifyListeners(TransactionManagerUpdateAdd(transactions));
  }

  void insertTransaction(int index, T transaction) {
    print('\ninsertTransaction');
    print(jsonEncode(transaction.toMap()));
    transactionQueue = List.unmodifiable(
        transactionQueue.sublist(0)..insert(index, transaction));
    notifyListeners(TransactionManagerUpdateAdd([transaction]));
  }

  void insertTransactions(int index, Iterable<T> transactions) {
    print('\ninsertTransactionS');
    print(jsonEncode(
        transactions.map((transaction) => transaction.toMap()).toList()));
    transactionQueue = List.unmodifiable(
        transactionQueue.sublist(0)..insertAll(index, transactions));
    notifyListeners(TransactionManagerUpdateAdd(transactions));
  }

  void removeTransactionsById(Iterable<String> ids) {
    print('\nremoveTransactionsById');
    print(jsonEncode(ids.toList()));
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
      notifyListeners(TransactionManagerUpdateRemove(removed));
    }
  }

  @protected
  void notifyListeners(TransactionManagerUpdate<T> update) {
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
