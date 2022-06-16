import 'package:stater/stater.dart';

class CascadeCachingDelegate extends LockingStorageDelegate {
  final Future<dynamic> _dataFuture;
  final Future<dynamic> _uncommittedTransactionsFuture;
  Error? _initError;
  dynamic _initErrorStackTrace;
  final InMemoryDelegate Function(Map<String, Map<String, dynamic>>)
      _innerDelegateCreator;

  CascadeCachingDelegate({
    required Future<dynamic> dataFuture,
    required Future<dynamic> uncommittedTransactionsFuture,
    InMemoryDelegate Function(Map<String, Map<String, dynamic>>)?
        innerDelegateCreator,
  })  : _dataFuture = dataFuture,
        _uncommittedTransactionsFuture = uncommittedTransactionsFuture,
        _innerDelegateCreator =
            innerDelegateCreator ?? ((data) => InMemoryDelegate(data)),
        super((innerDelegateCreator ?? ((data) => InMemoryDelegate(data)))(
            <String, Map<String, dynamic>>{})) {
    /// start by adding CascadeCachingDelegate initialization
    /// as a blocking transaction to the transactionQueue
    /// so any incoming transactions initiated by the user
    /// can not be started until the init process is completed
    requestLockingOperation(
      () {
        return Future.wait([_dataFuture, _uncommittedTransactionsFuture])
            .then((dataAndTransactions) {
          final data = dataAndTransactions.first;

          final transactions = dataAndTransactions.last;

          replaceDelegate(_innerDelegateCreator(data));

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
