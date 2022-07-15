import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:stater/src/transaction/transaction.dart';

class TransactionManager<T extends Transaction> {
  @protected
  final List<Function(TransactionManagerEvent<T>)> listeners = [];

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
    notifyListeners(TransactionManagerAddEvent([transaction]));
  }

  void addTransactions(Iterable<T> transactions) {
    // print('\naddTransactionS');
    // print(jsonEncode(
    //     transactions.map((transaction) => transaction.toMap()).toList()));
    transactionQueue =
        List.unmodifiable([...transactionQueue, ...transactions]);
    notifyListeners(TransactionManagerAddEvent(transactions));
  }

  void insertTransaction(int index, T transaction) {
    if (index == transactionQueue.length) {
      addTransaction(transaction);
    } else {
      transactionQueue =
          List.unmodifiable([...transactionQueue]..insert(index, transaction));

      notifyListeners(TransactionManagerInsertEvent(
          inserted: [transaction], startIndex: index));
    }
  }

  void insertTransactions(int index, Iterable<T> transactions) {
    if (transactions.isEmpty) {
      return;
    } else if (index == transactionQueue.length) {
      addTransactions(transactions);
    } else {
      // print('\ninsertTransactionS');
      // print(jsonEncode(
      //     transactions.map((transaction) => transaction.toMap()).toList()));
      transactionQueue = List.unmodifiable(
          [...transactionQueue]..insertAll(index, transactions));

      notifyListeners(TransactionManagerInsertEvent(
          inserted: transactions, startIndex: index));
    }
  }

  void removeTransactionsById(Iterable<String> ids) {
    // print('\nremoveTransactionsById');
    // print(jsonEncode(ids.toList()));
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
      notifyListeners(TransactionManagerRemoveEvent(removed));
    }
  }

  /// Replaces a range of elements with the elements of [replacements].
  ///
  /// Removes the transactions in the range from [start] to [end],
  /// then inserts the elements of [replacements] at [start].
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// final replacements = [6, 7];
  /// numbers.replaceRange(1, 4, replacements);
  /// print(numbers); // [1, 6, 7, 5]
  /// ```
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if 0 ≤ `start` ≤ `end` ≤ [length].
  /// An empty range (with `end == start`) is valid.
  ///
  /// The operation `list.replaceRange(start, end, replacements)`
  /// is roughly equivalent to:
  /// ```dart
  /// final numbers = <int>[1, 2, 3, 4, 5];
  /// numbers.removeRange(1, 4);
  /// final replacements = [6, 7];
  /// numbers.insertAll(1, replacements);
  /// print(numbers); // [1, 6, 7, 5]
  /// ```
  /// but may be more efficient.
  void replaceTransactions(int start, int end, Iterable<T> replacements) {
    if (end - start > 1 || replacements.isNotEmpty) {
      final removed = transactionQueue.sublist(start, end);

      transactionQueue = List<T>.unmodifiable(
          [...transactionQueue]..replaceRange(start, end, replacements));

      if (removed.isNotEmpty && replacements.isNotEmpty) {
        notifyListeners(TransactionManagerReplaceRangeEvent(
            inserted: replacements, removed: removed, startIndex: start));
      } else if (removed.isNotEmpty) {
        notifyListeners(TransactionManagerRemoveEvent(removed));
      } else {
        notifyListeners(TransactionManagerInsertEvent(
            inserted: replacements, startIndex: start));
      }
    }
  }

  @protected
  void notifyListeners(TransactionManagerEvent<T> update) {
    for (var listener in listeners) {
      listener.call(update);
    }
  }
}

abstract class TransactionManagerEvent<T> {}

class TransactionManagerAddEvent<T extends Transaction>
    extends TransactionManagerEvent<T> {
  final Iterable<T> added;

  TransactionManagerAddEvent(this.added);
}

class TransactionManagerInsertEvent<T extends Transaction>
    extends TransactionManagerEvent<T> {
  final Iterable<T> inserted;
  final int startIndex;

  TransactionManagerInsertEvent({
    required this.inserted,
    required this.startIndex,
  });
}

class TransactionManagerRemoveEvent<T extends Transaction>
    extends TransactionManagerEvent<T> {
  final Iterable<T> removed;

  TransactionManagerRemoveEvent(this.removed);
}

class TransactionManagerReplaceRangeEvent<T extends Transaction>
    extends TransactionManagerEvent<T> {
  final Iterable<T> inserted;
  final Iterable<T> removed;
  final int startIndex;

  TransactionManagerReplaceRangeEvent({
    required this.inserted,
    required this.removed,
    required this.startIndex,
  });
}
