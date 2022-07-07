// ignore_for_file: avoid_print

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

import 'cascade_in_memory_cache.dart';

class CascadeTransactionManager<T extends ExclusiveTransaction>
    extends TransactionManager<T> {
  @protected
  final List<StorageAdapter> delegates;

  @protected
  final TransactionStorer transactionStoringDelegate;

  /// Holds a map of all TransactionProcessors.
  /// Every storage (primary + caching ones) has
  /// exactly one TransactionProcessor
  @protected
  late Map<StorageAdapter, TransactionProcessor> processorMap;

  /// in-memory Storage that performs all transactions on
  /// cached DB data that is going to be used when user reads data
  /// from collections
  @protected
  late CascadeInMemoryCache cascadeInMemory;

  @protected
  late CancelableOperation<List<dynamic>> initFuture;

  /// list of all transactions successfully processed by all Storage delegates
  @protected
  List<T> completedTransactions = List.unmodifiable(const []);

  /// are there any changes in the transaction state that need to be saved
  bool _transactionStateHasUnsavedChanges = false;

  /// is there a write operation of transaction state in progress
  bool _isWritingTransactionState = false;

  @protected
  ServiceProcessorFactory? serviceProcessorFactory;

  CascadeTransactionManager({
    required this.delegates,
    required this.transactionStoringDelegate,
    this.serviceProcessorFactory,
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

    initFuture = CancelableOperation.fromFuture(
      Future.wait([
        transactionStoringDelegate.readTransactions(),
        transactionStoringDelegate.readProcessedState(),
      ]),
    );

    final cascadeInMemoryDataCompleter = Completer();

    cascadeInMemory = CascadeInMemoryCache(
      dataFuture: cascadeInMemoryDataCompleter.future,
      uncommittedTransactionsFuture: Future.value([]),
      serviceProcessorFactory: serviceProcessorFactory,
    );

    // after successful fetchingUncommittedTransactionsFromPreviousSession
    // continue with the setup of transaction processing
    initFuture.then((List<dynamic> transactionsAndState) {
      final storedTransactions =
          Transaction.fromListOfMap(transactionsAndState[0]);

      final storedTransactionsState =
          fromStoredTransactionsState(transactionsAndState[1]);

      if (storedTransactions.isNotEmpty) {
        transactionQueue = [
          ...storedTransactions.cast<T>(),
          ...transactionQueue,
        ];
      }

      /// forward all transactions (stored + arrived during the initialization)
      /// to the cascadeInMemory
      // TODO: fix this
      // for (var transaction in transactionQueue) {
      //   cascadeInMemory.performTransaction(transaction);
      // }

      /// fill cascadeInMemory initialState from one of [delegates]
      final sourceDataDelegateIndex = delegates
          .lastIndexWhere((delegate) => delegate is StorageHasRootAccess);

      if (sourceDataDelegateIndex < 0) {
        throw 'CascadeTransactionManager.init: at least one child delegate must '
            'implement StorageHasRootAccess interface.\n'
            'This delegate will be used to spawn in-memory cache storage';
      }

      final sourceDataDelegate =
          delegates[sourceDataDelegateIndex] as StorageHasRootAccess;

      sourceDataDelegate
          .getAllData()
          .then(cascadeInMemoryDataCompleter.complete)
          .catchError(cascadeInMemoryDataCompleter.completeError);

      // TODO: sourceDataDelegate should not be used by a processor
      // TODO: until sourceDataDelegate.getAllData is completed
      // TODO: to prevent writing new data before the reading is completed

      /// create processors
      processorMap = Map.fromEntries(
        delegates.map(
          (delegate) => MapEntry(
            delegate,
            TransactionProcessor(
                storage: delegate,
                completedTransactionIds:
                    storedTransactionsState[delegate.id] ?? {}),
          ),
        ),
      );

      if (transactionQueue.isNotEmpty) {
        notifyListeners(TransactionManagerUpdateAdd(transactionQueue));

        // there may be some transactions coming from the transaction storage or
        // some transactions may have arrived during the initialization,
        // so let's start processing the transactionQueue
        _employProcessors();
      }
    });
  }

  void destroy() {
    listeners.remove(_handleTransactionListChange);

    initFuture.cancel();

    // cancel all transactions currently being processed by a processor
    // TODO: fix this
    // for (var processor in processorMap.values) {
    //   processor.cancelCurrentTransaction();
    // }
    // and clear processorMap
    processorMap.clear();
  }

  @override
  void notifyListeners(TransactionManagerUpdate<T> update) {
    if (update is TransactionManagerUpdateAdd) {
      for (var transaction in (update as TransactionManagerUpdateAdd).added) {
        cascadeInMemory.performTransaction(transaction);
      }
    } else {
      throw 'CascadeTransactionManager.notifyListeners can only forward added '
          'transactions to the "cascadeInMemory". '
          'Not sure how to handle update of type "${update.runtimeType}"';
    }

    if (initFuture.isCompleted) {
      _handleTransactionListChange(update);
    }
    super.notifyListeners(update);
  }

  T? _findNextUncompletedTransaction(
    TransactionProcessor processor, {
    T? mustBeBeforeTransaction,
  }) {
    for (var transaction in transactionQueue) {
      if (mustBeBeforeTransaction == transaction) break;

      if (!transaction.excludeDelegateWithIds.contains(processor.storage.id) &&
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
      // more saveTransactionState requests may arrive
      // within next few microseconds
      // and we want to aggregate them into one write operation
      Future.delayed(const Duration(milliseconds: 1)).then((_) {
        _isWritingTransactionState = true;

        _transactionStateHasUnsavedChanges = false;

        return transactionStoringDelegate.writeState(
          transactions: Transaction.toListOfMap(transactionQueue
              .map((transaction) => transaction.withoutReadOperations())
              .where((transaction) => transaction.isNotEmpty())
              .toList()),
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
                  .contains(processor.storage.id) ||
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

      completedTransactions = [...completedTransactions, firstTransaction];

      print('\nremoving transaction "${firstTransaction.id}" from queue');

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
      T? previousProcessorTransaction;

      delegates.forEachIndexed((index, delegate) {
        // final isPrimaryProcessor = index == 0;

        final processor = processorMap[delegate]!;

        if (!processor.isPerformingTransaction) {
          final transaction = _findNextUncompletedTransaction(
            processor,
            mustBeBeforeTransaction: previousProcessorTransaction,
          );

          if (transaction != null) {
            print(
                '\nemploying: "${processor.storage.id}" with "${transaction.toJson()}"');

            processor.performTransaction(
              transaction,
              onSuccess: (data) {
                print('\n"${processor.storage.id}" completed '
                    '"${transaction.toJson()}"');
                processor.completedTransactionIds.add(transaction.id);
                if (transaction.isNotCompleted) {
                  transaction.complete(data);
                }
                _cleanUpCompletedTransaction();
                _employProcessors();
              },
            );
          }
        }

        previousProcessorTransaction =
            processor.currentTransaction as T? ?? previousProcessorTransaction;
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

  Set<String>? completedTransactionsIds(StorageAdapter delegate) {
    return processorMap[delegate]?.completedTransactionIds;
  }
}

Map<String, Set<String>> fromStoredTransactionsState(
    Map<String, dynamic>? rawData) {
  return rawData?.map((key, value) => MapEntry(key, Set<String>.from(value))) ??
      {};
}

Map<String, dynamic> toStoredTransactionsState(
    Map<StorageAdapter, TransactionProcessor> processorMap) {
  return processorMap.map(
      (key, value) => MapEntry(key.id, value.completedTransactionIds.toList()));
}
