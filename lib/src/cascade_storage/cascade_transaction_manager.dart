// ignore_for_file: avoid_print

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:stater/src/cascade_storage/exclusive_transaction.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/transaction/transaction.dart';
import 'package:stater/src/transaction/transaction_manager.dart';
import 'package:stater/src/transaction/transaction_processor.dart';
import 'package:stater/src/transaction/transaction_storing_delegate.dart';

class CascadeTransactionManager<T extends ExclusiveTransaction>
    extends TransactionManager<T> {
  @protected
  final List<CascadableStorageDelegate> delegates;

  @protected
  final TransactionStoringDelegate transactionStoringDelegate;

  @protected
  late Map<CascadableStorageDelegate, TransactionProcessor> processorMap;

  bool _isInit = false;
  late CancelableOperation? _cancelInit;

  /// future for reading of previouslySavedTransactionState
  late final Future<void> initFuture;

  /// are there any changes in the transaction state that need to be saved
  bool _transactionStateHasUnsavedChanges = false;

  /// is there a write operation of transaction state in progress
  bool _isWritingTransactionState = false;

  CascadeTransactionManager({
    required this.delegates,
    required this.transactionStoringDelegate,
  }) {
    final idDuplicates = delegates
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
        delegates.isNotEmpty,
        'CascadeTransactionManager.constructor: '
        'list of delegates can not be empty');

    assert(
        idDuplicates.isEmpty,
        'CascadeTransactionManager.constructor: '
        'delegate ids must be unique. Got $idDuplicates');

    processorMap = {};

    listeners.add(_handleTransactionListChange);

    initFuture = Future.wait([
      transactionStoringDelegate.readTransactions(),
      transactionStoringDelegate.readProcessedState(),
    ]).then(_completeInit);

    _cancelInit = CancelableOperation.fromFuture(initFuture);
  }

  void destroy() {
    listeners.remove(_handleTransactionListChange);
    if (!_isInit) {
      _cancelInit?.cancel();
    } else {
      // cancel all transactions currently being processed by a processor
      for (var processor in processorMap.values) {
        processor.cancelCurrentTransaction();
      }
    }
  }

  void _completeInit(List<dynamic> transactionsAndState) {
    if (!_isInit) {
      _cancelInit = null;

      final storedTransaction =
          Transaction.fromListOfMap(transactionsAndState[0] ?? []);

      final storedTransactionsState =
          fromStoredTransactionsState(transactionsAndState[1]);

      processorMap = Map.fromEntries(
        delegates.map(
          (delegate) => MapEntry(
            delegate,
            TransactionProcessor(
                delegate: delegate,
                completedTransactionIds:
                    storedTransactionsState[delegate.id] ?? {}),
          ),
        ),
      );

      if (storedTransaction.isNotEmpty) {
        transactionQueue = [
          ...storedTransaction.cast<T>(),
          ...transactionQueue,
        ];
      }

      if (transactionQueue.isNotEmpty) {
        notifyListeners(TransactionManagerUpdateAdd(transactionQueue));

        // there may be some transactions coming from the transaction storage or
        // some transactions may have arrived during the initialization,
        // so let's start committing
        _employProcessors();
      }

      _isInit = true;
    }
  }

  @override
  void notifyListeners(TransactionManagerUpdate<T> update) {
    if (_isInit) {
      super.notifyListeners(update);
    }
  }

  T? _findNextUncompletedTransaction(
    TransactionProcessor processor, {
    T? mustBeBeforeTransaction,
  }) {
    for (var transaction in transactionQueue) {
      if (mustBeBeforeTransaction == transaction) break;

      if (!transaction.excludeDelegateWithIds.contains(processor.delegate.id) &&
          !processor.completedTransactionIds.contains(transaction.id)) {
        return transaction;
      }
    }
    return null;
  }

  void saveTransactionState() {
    if (_transactionStateHasUnsavedChanges && _isWritingTransactionState) {
      return;
    } else if (_isWritingTransactionState) {
      _transactionStateHasUnsavedChanges = true;
    } else {
      // wait for a short while before writing
      // it may arrive more saveTransactionState requests
      // within next few microseconds
      // and we want to aggregate them into one write operation
      Future.delayed(const Duration(milliseconds: 1)).then((_) {
        _isWritingTransactionState = true;

        _transactionStateHasUnsavedChanges = false;

        return transactionStoringDelegate.writeState(
          transactions: Transaction.toListOfMap(transactionQueue),
          processedState: toStoredTransactionsState(processorMap),
        );
      }).then((_) {
        _isWritingTransactionState = false;

        if (_transactionStateHasUnsavedChanges) {
          saveTransactionState();
        }
      }).catchError((_) {
        _isWritingTransactionState = false;

        _transactionStateHasUnsavedChanges == true;
      });
    }
  }

  /// removes transactions processed by every processor from transactionQueue
  /// and removes ids of removedTransactions from every
  /// processor.completedTransactionIds set
  _cleanUpCompletedTransaction() {
    bool thereWasCleaning = false;

    bool firstTransactionIsCommittedByEveryProcessor() {
      if (transactionQueue.isEmpty) {
        return false;
      } else {
        final firstTransaction = transactionQueue.first;

        bool processorHasCompletedFirstTransaction(processor) {
          bool result = firstTransaction.excludeDelegateWithIds
                  .contains(processor.delegate.id) ||
              processor.completedTransactionIds.contains(firstTransaction.id);
          return result;
        }

        final all =
            processorMap.values.every(processorHasCompletedFirstTransaction);
        return all;
      }
    }

    while (firstTransactionIsCommittedByEveryProcessor()) {
      thereWasCleaning = true;

      final firstTransaction = transactionQueue.first;

      processorMap.forEach((key, value) {
        value.completedTransactionIds.remove(firstTransaction.id);
      });

      transactionQueue = transactionQueue.sublist(1);
    }

    if (thereWasCleaning) saveTransactionState();
  }

  /// iterates over list of processors and feeds a transaction to a free one
  ///
  /// with limitation that non-primary processors can not process a transaction
  /// if it has not been completed successfully by the primary processor
  void _employProcessors() {
    if (transactionQueue.isNotEmpty) {
      T? primaryProcessorTransaction;

      delegates.forEachIndexed((index, delegate) {
        final isPrimaryProcessor = index == 0;

        final processor = processorMap[delegate]!;

        if (!processor.isPerformingTransaction) {
          final transaction = _findNextUncompletedTransaction(
            processor,
            mustBeBeforeTransaction:
                isPrimaryProcessor ? null : primaryProcessorTransaction,
          );

          if (transaction != null) {
            processor.performTransaction(
              transaction,
              onSuccess: (_) {
                processor.completedTransactionIds.add(transaction.id);
                _cleanUpCompletedTransaction();
                _employProcessors();
              },
            );

            if (isPrimaryProcessor) {
              primaryProcessorTransaction = transaction;
            }
          }
        }
      });
    }
  }

  void _handleTransactionAdd(Iterable<T> added) {
    _employProcessors();
  }

  void _handleTransactionRemove(Iterable<T> removed) {
    bool transactionCancelingHappened = false;

    processorMap.forEach((_, processor) {
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

  void _handleTransactionListChange(TransactionManagerUpdate<T> update) {
    if (update is TransactionManagerUpdateRemove<T>) {
      _handleTransactionRemove(update.removed);
    } else if (update is TransactionManagerUpdateAdd<T>) {
      _handleTransactionAdd(update.added);
    } else {
      throw 'Unsupported type of TransactionManagerUpdate '
          '"${update.runtimeType}"';
    }

    saveTransactionState();
  }

  @override
  void dispose() {
    processorMap.forEach((_, processor) => processor.dispose());
    listeners.clear();
  }

  Set<String>? completedTransactionsIds(CascadableStorageDelegate delegate) {
    return processorMap[delegate]?.completedTransactionIds;
  }
}

Map<String, Set<String>> fromStoredTransactionsState(
    Map<String, dynamic>? rawData) {
  return rawData?.map((key, value) => MapEntry(key, Set<String>.from(value))) ??
      {};
}

Map<String, dynamic> toStoredTransactionsState(
    Map<CascadableStorageDelegate, TransactionProcessor> processorMap) {
  return processorMap.map(
      (key, value) => MapEntry(key.id, value.completedTransactionIds.toList()));
}
