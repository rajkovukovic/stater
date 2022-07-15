import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

/// InMemory storage, used by CascadeStorage as a cache,
/// performs all transactions from the queue without waiting
/// for other CascadeDelegates.<br>
/// Used to perform all transactions as soon as they are created,
/// so it always has the latest state which is used to perform all read
/// transactions against
class CascadeCache extends LockingAdapter {
  final Future<dynamic> _dataFuture;
  final Future<dynamic> _uncommittedTransactionsFuture;
  Error? _initError;
  dynamic _initErrorStackTrace;

  /// makes a data snapshot of whole inMemoryStorage after every
  /// successful transaction processing
  @protected
  final List<InMemoryHistoryState> history = [];

  CascadeCache({
    required Future<dynamic> dataFuture,
    required Future<dynamic> uncommittedTransactionsFuture,
    ServiceProcessorFactory? serviceProcessorFactory,
  })  : _dataFuture = dataFuture,
        _uncommittedTransactionsFuture = uncommittedTransactionsFuture,
        super(
          InMemoryAdapter({}, id: 'CascadeInMemoryCache -> InMemoryAdapter'),
          // we want even read operations to wait all prior write operations
          // to complete, so read data is up-to-date
          lockingStrategy: const EveryOperationLocks(),
        ) {
    /// start by adding CascadeCachingDelegate initialization
    /// as a blocking transaction to the transactionQueue
    /// so any incoming transactions, arrived during the init process,
    /// can not be started until the init process is completed
    requestWriteOperation(
      () {
        return Future.wait([_dataFuture, _uncommittedTransactionsFuture])
            .then((dataAndTransactions) {
          final data = dataAndTransactions.first;

          final transactions = dataAndTransactions.last;

          // now we have initial data, let's use it in innerDelegate
          (delegate as InMemoryAdapter).data = data;

          // save any transactions arrived during init process
          final transactionsArrivedDuringInit = [...operationsQueue];

          // clear operation queue
          operationsQueue.clear();

          // add all transactions from _uncommittedTransactionsFuture
          // to the transactionQueue
          transactions.forEach((transaction) {
            performTransaction(transaction);
          });

          // return transactionsArrivedDuringInit to the transactionQueue
          operationsQueue.addAll(transactionsArrivedDuringInit);
        });
      },
      {'caller': 'CascadeCachingDelegate.init'},
    ).catchError(
      (error, stackTrace) {
        _initError = error;
        _initErrorStackTrace = stackTrace;
      },
    );
  }

  @override
  Future performTransaction(Transaction transaction,
      {doOperationsInParallel = false, options = const StorageOptions()}) {
    final request = super.performTransaction(transaction,
        doOperationsInParallel: doOperationsInParallel, options: options);

    request.then((_) => history.addBetween(InMemoryHistoryState(
        dataSnapshot: (delegate as InMemoryAdapter).immutableData,
        transactionId: transaction.id)));

    return request;
  }

  @override
  Future executeFromQueue() async {
    if (_initError != null) {
      // make all pending transactions throw _initError
      // so it can propagate to the UI
      for (var queueItem in operationsQueue) {
        queueItem.completer.completeError(
          'CascadeCachingDelegate init failed with error: '
          '${_initError.toString()}',
          _initErrorStackTrace,
        );
      }
      operationsQueue.clear();
      return Future.error(_initError!, _initErrorStackTrace);
    } else {
      return super.executeFromQueue();
    }
  }

  /// removes a history snapshot,
  /// but does not change the current data state of this storage
  bool removeHistoryState(String transactionId) {
    final index = history.indexWhere(
        (historyState) => historyState.transactionId == transactionId);

    if (index >= 0) {
      history.removeAt(index);
      return true;
    }

    return false;
  }

  /// restores this storage to an earlier snapshot right after the transaction
  /// with id=transactionId has been performed
  bool goToHistoryState(String transactionId) {
    final index = history.indexWhere(
        (historyState) => historyState.transactionId == transactionId);

    if (index >= 0) {
      history.removeRange(index + 1, history.length);
      (delegate as InMemoryAdapter).immutableData = history.last.dataSnapshot;
      return true;
    }

    return false;
  }
}

class InMemoryHistoryState {
  final IMap<String, IMap<String, dynamic>> dataSnapshot;
  final String transactionId;

  InMemoryHistoryState({
    required this.dataSnapshot,
    required this.transactionId,
  });
}
