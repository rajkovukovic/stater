import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:stater/stater.dart';

class CascadeCachingDelegate extends LockingStorageDelegate {
  final Future<dynamic> _dataFuture;
  final Future<dynamic> _uncommittedTransactionsFuture;
  Error? _initError;
  dynamic _initErrorStackTrace;

  CascadeCachingDelegate({
    required Future<dynamic> dataFuture,
    required Future<dynamic> uncommittedTransactionsFuture,
  })  : _dataFuture = dataFuture,
        _uncommittedTransactionsFuture = uncommittedTransactionsFuture,
        super(InMemoryDelegate.fromImmutableData(IMap())) {
    /// start by adding CascadeCachingDelegate initialization
    /// as a blocking transaction to the transactionQueue
    /// so any incoming transactions initiated by the user
    /// can not be started until the init process is completed
    requestLockingOperation(() {
      return Future.wait([_dataFuture, _uncommittedTransactionsFuture])
          .then((dataAndTransactions) {
        final data = dataAndTransactions.first;

        final transactions = dataAndTransactions.last;

        replaceDelegate(InMemoryDelegate(data));

        // save any transactions arrived during init process
        final transactionsArrivedDuringInit = [...transactionQueue];

        // clear operation queue
        transactionQueue.clear();

        // add all transactions from _uncommittedTransactionsFuture
        // to the transactionQueue
        transactions.forEach(performTransaction);

        // return transactionsArrivedDuringInit to the transactionQueue
        transactionQueue.addAll(transactionsArrivedDuringInit);
      });
    }).catchError((error, stackTrace) {
      _initError = error;
      _initErrorStackTrace = stackTrace;
    });
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
