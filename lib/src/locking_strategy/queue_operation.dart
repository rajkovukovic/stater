import 'dart:async';

import 'package:stater/stater.dart';

class QueueOperation {
  final Future Function() performer;
  final bool isReadOperation;
  final Completer completer;
  final dynamic debugData;

  QueueOperation({
    required this.performer,
    required this.isReadOperation,
    required this.completer,
    this.debugData,
  });

  Future<dynamic> performWithRetry([RetryStrategy? retryStrategy]) {
    int retryIndex = -1;
    dynamic response;

    return Future.doWhile(() {
      return performer().then((value) {
        response = value;
        return false;
      }).catchError((transactionError, stackTrace) {
        if (retryStrategy != null) {
          retryIndex += 1;
          return retryStrategy
              .getNextRetry(retryIndex: retryIndex++)
              // return true so Future.doWhile can resume retying
              .then((_) => true)
              .catchError((retryStrategyError) =>
                  throw '($retryStrategyError) $transactionError');
        } else {
          /// if there is no retry strategy
          /// rethrow the transaction error
          throw transactionError;
        }
      });
    }).then((_) {
      completer.complete(response);
      return response;
    });
  }
}
