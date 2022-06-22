import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stater/stater.dart';

const _retrySequencesInMilliseconds = [1000, 2000, 4000];

/// Processes a transaction and retries forever
class TransactionProcessor {
  final CascadableStorage storage;
  final Set<String> completedTransactionIds;

  Transaction? currentTransaction;
  StreamSubscription? _currentTransactionSubscription;

  TransactionProcessor({
    required this.storage,
    required this.completedTransactionIds,
  });

  bool get isPerformingTransaction => _currentTransactionSubscription != null;

  void dispose() {
    cancelCurrentTransaction();
  }

  void cancelCurrentTransaction() {
    _currentTransactionSubscription?.cancel();
    _currentTransactionSubscription = null;
    currentTransaction = null;
  }

  void _handleTransactionComplete(dynamic response, Function? onSuccess) {
    cancelCurrentTransaction();
    onSuccess?.call(response);
  }

  void performTransaction(
    Transaction transaction, {
    Function? onSuccess,
    Function? onError,
    int? retryCount,
  }) {
    if (isPerformingTransaction) {
      throw 'processor "${storage.id}" is already performing a transaction';
    }

    currentTransaction = transaction;

    int lastRetryDelay = 0;

    getRetryDelay() {
      if (lastRetryDelay == 0) {
        lastRetryDelay = _retrySequencesInMilliseconds.first;
      } else {
        lastRetryDelay = _retrySequencesInMilliseconds.firstWhere(
            (delay) => delay > lastRetryDelay,
            orElse: () => _retrySequencesInMilliseconds.last);
      }

      return Stream.fromFuture(
          Future.delayed(Duration(milliseconds: lastRetryDelay))
              .then((_) => Future.error('')));
    }

    final stream = RetryStream(
      () => Stream.fromFuture(storage.performTransaction(transaction)
              // transaction.operations.length == 1
              //   ? storage.performOperation(transaction.operations.first)
              //   : storage.performTransaction(transaction)
              )
          .onErrorResume((_, __) => getRetryDelay()),
      retryCount,
    );

    _currentTransactionSubscription = stream.listen(
      (response) => _handleTransactionComplete(response, onSuccess),
      onError: onError,
      cancelOnError: true,
    );
  }
}
