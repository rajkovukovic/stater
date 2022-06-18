import 'package:stater/stater.dart';

class CascadeCachingDelegate extends LockingStorage {
  final Future<dynamic> _dataFuture;
  final Future<dynamic> _uncommittedTransactionsFuture;
  Error? _initError;
  dynamic _initErrorStackTrace;

  CascadeCachingDelegate({
    required Future<dynamic> dataFuture,
    Future<dynamic>? uncommittedTransactionsFuture,
    ServiceRequestProcessorFactory? serviceRequestProcessorFactory,
  })  : _dataFuture = dataFuture,
        _uncommittedTransactionsFuture =
            uncommittedTransactionsFuture ?? Future.value([]),
        super(
          LockingInMemoryDelegate(
            <String, Map<String, dynamic>>{},
            serviceRequestProcessorFactory: serviceRequestProcessorFactory,
          ),
        ) {
    /// start by adding CascadeCachingDelegate initialization
    /// as a blocking transaction to the transactionQueue
    /// so any incoming transactions, arrived during the init process,
    /// can not be started until the init process is completed
    requestLockingOperation(
      () {
        return Future.wait([_dataFuture, _uncommittedTransactionsFuture])
            .then((dataAndTransactions) {
          final data = dataAndTransactions.first;

          final transactions = dataAndTransactions.last;

          // now we have initial data, let's use it in innerDelegate
          (delegate as HasCacheStorage).data = data;

          // save any transactions arrived during init process
          final transactionsArrivedDuringInit = [...transactionQueue];

          // clear operation queue
          transactionQueue.clear();

          // add all transactions from _uncommittedTransactionsFuture
          // to the transactionQueue
          transactions.forEach((transaction) {
            performTransaction(transaction);
          });

          // return transactionsArrivedDuringInit to the transactionQueue
          transactionQueue.addAll(transactionsArrivedDuringInit);
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
      for (var queueItem in transactionQueue) {
        queueItem.completer.completeError(
            'CascadeCachingDelegate init failed with error: ${_initError.toString()}',
            _initErrorStackTrace);
      }
      transactionQueue.clear();
      return Future.error(_initError!, _initErrorStackTrace);
    } else {
      return super.executeFromQueue();
    }
  }
}
