import 'package:stater/stater.dart';

/// InMemory storage, used by CascadeStorage, performs all transactions
/// from the queue without waiting for other CascadeDelegates.<br>
/// Used to perform all transactions
class CascadeInMemoryCache extends LockingAdapter {
  final Future<dynamic> _dataFuture;
  final Future<dynamic> _uncommittedTransactionsFuture;
  Error? _initError;
  dynamic _initErrorStackTrace;

  CascadeInMemoryCache({
    required Future<dynamic> dataFuture,
    required Future<dynamic> uncommittedTransactionsFuture,
    ServiceProcessorFactory? serviceProcessorFactory,
  })  : _dataFuture = dataFuture,
        _uncommittedTransactionsFuture = uncommittedTransactionsFuture,
        super(
          InMemoryAdapter({}, id: 'CascadeInMemoryCache -> InMemoryAdapter'),
          // we want even read operations to wait all prior write operations
          // so read data is up-to-date
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
}
