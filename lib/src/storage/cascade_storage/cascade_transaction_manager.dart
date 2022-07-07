// ignore_for_file: avoid_print

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:stater/src/utils/read_transaction_data_to_write_transaction.dart';
import 'package:stater/stater.dart';

import 'cascade_cache.dart';

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
  late CascadeCache inMemoryCache;

  @protected
  late CancelableOperation<List<dynamic>> initFuture;

  /// list of all transactions successfully processed by all Storage delegates
  @protected
  List<T> completedTransactions = List.unmodifiable(const []);

  /// are there any changes in the transaction state that need to be saved
  bool _transactionStateHasUnsavedChanges = false;

  /// is there a write operation of transactions state in progress
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

    inMemoryCache = CascadeCache(
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
      /// to the cascadeCache
      // TODO: fix this
      // for (var transaction in transactionQueue) {
      //   cascadeInMemory.performTransaction(transaction);
      // }

      /// fill cascadeInMemory initialState from one of [delegates].
      final sourceDataDelegateIndex = delegates
          .lastIndexWhere((delegate) => delegate is StorageHasRootAccess);

      if (sourceDataDelegateIndex < 0) {
        throw 'CascadeTransactionManager.init: at least one child delegate '
            'must implement StorageHasRootAccess interface.\n'
            'This delegate will be used to spawn in-memory cache storage';
      }

      final sourceDataDelegate =
          delegates[sourceDataDelegateIndex] as StorageHasRootAccess;

      sourceDataDelegate.getAllData().then((value) {
        cascadeInMemoryDataCompleter.complete(value);
      }).catchError((error) {
        cascadeInMemoryDataCompleter.completeError(error);
      });

      // TODO: sourceDataDelegate should not be used by a processor
      // TODO: until sourceDataDelegate.getAllData is completed
      // TODO: to prevent writing of new data before the reading is completed

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
        notifyListeners(TransactionManagerAddEvent(transactionQueue));

        // there may be some transactions coming from the transaction storage or
        // some transactions may have arrived during the initialization,
        // so let's start processing the transactionQueue
        _employAllProcessors();
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
  void notifyListeners(TransactionManagerEvent<T> update) {
    if (update is TransactionManagerAddEvent<T>) {
      for (var transaction in (update).added) {
        inMemoryCache.performTransaction(transaction);
      }
    } else {
      // inMemoryCache needs to go back in time and redo some transactions
      late int indexOfFirstTransactionToProcess;

      if (update is TransactionManagerInsertEvent<T>) {
        indexOfFirstTransactionToProcess = (update).startIndex;
      } else if (update is TransactionManagerReplaceRangeEvent<T>) {
        indexOfFirstTransactionToProcess = (update).startIndex;
      } else {
        throw 'CascadeTransactionManager.notifyListeners can only forward added '
            'transactions to the "cascadeInMemory". '
            'Not sure how to handle update of type "${update.runtimeType}"';
      }

      final indexOfLastTransactionToKeep = indexOfFirstTransactionToProcess == 0
          ? 0
          : indexOfFirstTransactionToProcess - 1;

      final transactionsToProcess =
          transactionQueue.sublist(indexOfFirstTransactionToProcess);

      inMemoryCache
          .goToHistoryState(transactionQueue[indexOfLastTransactionToKeep].id);

      for (var transaction in transactionsToProcess) {
        inMemoryCache.performTransaction(transaction);
      }
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

  _removeFirstTransactionFromQueue() {
    final firstTransaction = transactionQueue.first;

    completedTransactions = [...completedTransactions, firstTransaction];

    print('\nremoving transaction "${firstTransaction.id}" from queue');

    processorMap.forEach((key, value) {
      value.completedTransactionIds.remove(firstTransaction.id);
    });

    inMemoryCache.removeHistoryState(firstTransaction.id);

    transactionQueue = transactionQueue.sublist(1);
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

      _removeFirstTransactionFromQueue();
    }

    if (thereWasCleaning) saveTransactionState();
  }

  void _employOneProcessor(
    TransactionProcessor processor, {
    required T transaction,
    required int processorIndex,
  }) {
    // final isPrimaryProcessor = processorIndex == 0;
    // final isLastProcessor = processorIndex == delegates.length - 1;

    print('\nemploying: "${processor.storage.id}" with '
        '"${transaction.toJson()}"');

    processor.performTransaction(
      transaction,
      onSuccess: (data) {
        print('\n"${processor.storage.id}" completed '
            '"${transaction.toJson()}"');
        processor.completedTransactionIds.add(transaction.id);

        // notify all listeners that transaction has been completed
        if (transaction.isNotCompleted) {
          // TODO: apply all transactions from the queue to the data
          // to make sure returned data has all changes from all transactions
          // in the queue applied
          transaction.complete(results: data);
        }

        // on successful read, write read data to all subsequent Storages
        // we are using replaceRange, because subsequent Storages do not need
        // to perform this operation any more
        if (transaction.hasOnlyReadOperations) {
          final transactionIndex = transactionQueue.indexOf(transaction);

          if (transactionIndex < 0) {
            throw 'can not find the READ only transaction in '
                'order to replace it';
          }

          // start by storage that we got data from and it's
          // all subsequent storages
          final excludeStorages = delegates
              .sublist(0, processorIndex + 1)
              .map((storage) => storage.id)
              .toSet();

          // then add existing excluded storages, which were defined
          // in the read transaction
          excludeStorages.addAll(transaction.excludeDelegateWithIds);

          // create a write transaction containing a write operation for
          // every document we read by the read transaction
          final replacementTransaction = readTransactionDataToWriteTransaction(
            excludeDelegateWithIds: excludeStorages,
            readData: data,
            readTransaction: transaction,
          ) as T;

          // replace the read transaction with replacementTransaction
          replaceTransactions(
            transactionIndex,
            transactionIndex + 1,
            [replacementTransaction],
          );
        }

        _cleanUpCompletedTransaction();

        _employAllProcessors();
      },
      onError: (error) {
        print('\n"${processor.storage.id}" FAILED to complete '
            '"${transaction.toJson()}"');

        /// if a Read transaction fails,
        /// fallback to inMemoryCache for reading data.
        /// in case first Storage in list is a REST one and read request fails,
        /// we can not risk to fallback to next Storage because it may not
        /// have all transactions from the transactionQueue applied
        if (transaction.hasOnlyReadOperations) {
          inMemoryCache
              .performTransaction(transaction)
              .then((value) => transaction.complete(results: value))
              .catchError((error) => transaction.complete(withError: error));
        }

        // if (transaction.isNotCompleted && isLastProcessor) {
        //   transaction.complete([], withError: error);
        // }
        // _employAllProcessors();
      },
    );
  }

  /// iterates over list of processors and feeds a transaction to a free one
  ///
  /// with limitation that non-primary processors can not process a transaction
  /// if it has not been completed successfully by the primary processor
  void _employAllProcessors() {
    if (transactionQueue.isNotEmpty) {
      T? previousProcessorTransaction;

      delegates.forEachIndexed((index, delegate) {
        final processor = processorMap[delegate]!;

        if (!processor.isPerformingTransaction) {
          final transaction = _findNextUncompletedTransaction(
            processor,
            mustBeBeforeTransaction: previousProcessorTransaction,
          );

          if (transaction != null) {
            _employOneProcessor(
              processor,
              transaction: transaction,
              processorIndex: index,
            );
          }
        }

        previousProcessorTransaction =
            processor.currentTransaction as T? ?? previousProcessorTransaction;
      });
    }
  }

  void _handleTransactionAdd(Iterable<T> added) {
    _employAllProcessors();
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
      _employAllProcessors();
    }
  }

  void _handleTransactionListChange(TransactionManagerEvent<T> update) {
    if (update is TransactionManagerRemoveEvent<T>) {
      _handleTransactionRemove(update.removed);
    } else if (update is TransactionManagerReplaceRangeEvent<T>) {
      _handleTransactionRemove(update.removed);
    } else if (update is TransactionManagerAddEvent<T>) {
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
