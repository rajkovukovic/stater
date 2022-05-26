// ignore_for_file: avoid_print

import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/transaction/transaction.dart';
import 'package:stater/stater/transaction/transaction_manager.dart';

// const _retrySequencesInMilliseconds = [1000, 2000, 5000];

class CascadeTransactionManager extends TransactionManager {
  final List<AdapterDelegateWithId> _delegates;
  late final Map<String, _TransactionProcessor> _processorMap;

  CascadeTransactionManager(this._delegates) {
    final idDuplicates = _delegates
        .fold<Map<String, int>>({}, (acc, delegate) {
          acc[delegate.id] =
              acc.containsKey(delegate.id) ? acc[delegate.id]! + 1 : 1;
          return acc;
        })
        .entries
        .where((entry) => entry.value > 1)
        .map((entry) => '${entry.value}x "${entry.key}"')
        .join(', ');

    assert(
        idDuplicates.isEmpty, 'delegate ids must be unique. Got $idDuplicates');

    _processorMap = Map.fromEntries(
      _delegates.map(
        (delegate) => MapEntry(
          delegate.id,
          _TransactionProcessor(
              delegate: delegate, completedTransactionIds: {}),
        ),
      ),
    );

    listeners.add(_handleTransactionListChange);
  }

  Transaction? _findNextUncompletedTransaction(
      Set<String> completedTransactionIds) {
    for (var transaction in transactionQueue) {
      if (!completedTransactionIds.contains(transaction.id)) {
        return transaction;
      }
    }
    return null;
  }

  void _feedNextTransactionToProcessor(_TransactionProcessor processor) {
    final nextTransaction =
        _findNextUncompletedTransaction(processor.completedTransactionIds);
    if (nextTransaction != null) {
      processor.performTransaction(nextTransaction);
    }
  }

  void _handleTransactionAdd(Iterable<Transaction> added) {
    _processorMap.forEach((_, processor) {
      if (!processor.isPerformingTransaction) {
        _feedNextTransactionToProcessor(processor);
      }
    });
  }

  void _handleTransactionRemove(Iterable<Transaction> removed) {
    bool transactionCancelingHappened = false;

    _processorMap.forEach((_, processor) {
      if (processor.isPerformingTransaction &&
          removed.contains(processor.currentTransaction)) {
        processor.cancelCurrentTransaction();
        transactionCancelingHappened = true;
      }
    });

    // if there was a transaction canceling due to the transaction
    // being removed from the transaction queue
    // call _handleTransactionAdd to feed every free TransactionProcessor
    // with next available transaction
    if (transactionCancelingHappened) {
      _handleTransactionAdd([]);
    }
  }

  void _handleTransactionListChange(TransactionManagerUpdate update) {
    if (update is TransactionManagerUpdateRemove) {
      _handleTransactionRemove(update.removed);
    } else if (update is TransactionManagerUpdateAdd) {
      _handleTransactionAdd(update.added);
    } else {
      throw 'Unsupported type of TransactionManagerUpdate => ${update.runtimeType}';
    }
  }

  @override
  void dispose() {
    _processorMap.forEach((_, processor) => processor.dispose());
    listeners.clear();
  }
}

class _TransactionProcessor {
  final AdapterDelegateWithId delegate;
  final Set<String> completedTransactionIds;

  Transaction? currentTransaction;
  StreamSubscription? _currentTransactionSubscription;

  _TransactionProcessor(
      {required this.delegate, required this.completedTransactionIds});

  bool get isPerformingTransaction => _currentTransactionSubscription != null;

  void dispose() {
    cancelCurrentTransaction();
  }

  void cancelCurrentTransaction() {
    _currentTransactionSubscription?.cancel();
    _currentTransactionSubscription = null;
    currentTransaction = null;
  }

  Future _failAfter(int milliseconds, String message) {
    return Future.delayed(Duration(milliseconds: milliseconds)).then((_) {
      print(message);
      return Future.error(message);
    });
  }

  Stream _performTransactionAsStream(Transaction transaction,
      [bool shouldFail = false]) {
    print('performing transaction...');
    return Stream.fromFuture(shouldFail
        ? _failAfter(500, 'Server is down')
        : Future.delayed(const Duration(milliseconds: 500)));
  }

  void _handleTransactionComplete(dynamic maybeTransaction) {
    cancelCurrentTransaction();
  }

  void performTransaction(Transaction transaction) {
    if (isPerformingTransaction) {
      throw 'processor "${delegate.id}" is already performing a transaction';
    }

    currentTransaction = transaction;
    int counter = 0;
    _currentTransactionSubscription = RetryStream(
      () => _performTransactionAsStream(transaction, counter++ < 5)
          .onErrorResume(
              (_, __) => Stream.fromFuture(_failAfter(2000, 'retry timeout'))),
    ).listen(
      _handleTransactionComplete,
      onDone: () => print('performTransaction is Done'),
      onError: (error) => print('performTransaction error $error'),
    );
  }
}
