// ignore_for_file: avoid_print

import 'package:collection/collection.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/transaction/transaction.dart';
import 'package:stater/stater/transaction/transaction_manager.dart';
import 'package:stater/stater/transaction/transaction_processor.dart';

class CascadeTransactionManager extends TransactionManager {
  final List<AdapterDelegateWithId> _delegates;
  late final Map<AdapterDelegateWithId, TransactionProcessor> _processorMap;

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

    assert(_delegates.isNotEmpty, 'list of delegates can not be empty');
    assert(
        idDuplicates.isEmpty, 'delegate ids must be unique. Got $idDuplicates');

    _processorMap = Map.fromEntries(
      _delegates.map(
        (delegate) => MapEntry(
          delegate,
          TransactionProcessor(delegate: delegate, completedTransactionIds: {}),
        ),
      ),
    );

    listeners.add(_handleTransactionListChange);
  }

  TransactionProcessor get primaryProcessor => _processorMap[_delegates.first]!;

  Transaction? _findNextUncompletedTransaction(
    TransactionProcessor processor, {
    Transaction? mustBeBeforeTransaction,
  }) {
    for (var transaction in transactionQueue) {
      if (mustBeBeforeTransaction == transaction) break;
      if (!processor.completedTransactionIds.contains(transaction.id)) {
        return transaction;
      }
    }
    return null;
  }

  /// removes transactions processed by every processor from transactionQueue
  /// and removes ids of removedTransactions from every
  /// processor.completedTransactionIds set
  _cleanUpCompletedTransaction() {
    while (transactionQueue.isNotEmpty &&
        _processorMap.values.every((processor) => processor
            .completedTransactionIds
            .contains(transactionQueue.first.id))) {
      transactionQueue = transactionQueue.sublist(1);
    }
  }

  /// iterates list of processors and gives a transaction to any free one
  ///
  /// with limitation that non-primary processors can not process a transaction
  /// if it not been completed successfully by the primary processor
  void _employProcessors() {
    Transaction? primaryProcessorTransaction;

    _delegates.forEachIndexed((index, delegate) {
      final isPrimaryProcessor = index == 0;

      final processor = _processorMap[delegate]!;

      if (!processor.isPerformingTransaction) {
        final transaction = _findNextUncompletedTransaction(
          processor,
          mustBeBeforeTransaction:
              isPrimaryProcessor ? null : primaryProcessorTransaction,
        );

        if (transaction != null) {
          processor.performTransaction(transaction, onSuccess: (_) {
            processor.completedTransactionIds.add(transaction.id);
            _cleanUpCompletedTransaction();
            _employProcessors();
          });
        }
      }
    });
  }

  void _handleTransactionAdd(Iterable<Transaction> added) {
    _employProcessors();
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
    // call _handleTransactionAdd to feed every available TransactionProcessor
    // with next available transaction
    if (transactionCancelingHappened) {
      _employProcessors();
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
