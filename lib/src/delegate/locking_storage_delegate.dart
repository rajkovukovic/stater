import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stater/stater.dart';

/// Add locking mechanism to StorageDelegate, so all write operations will
/// delay read operations.
///
/// Write operations are executed sequentially.
///
/// Read operations can be performed in parallel.
///
/// ```
/// _operationQueue = [
///   DelegateOperation(getDocument, ...)
///   DelegateOperation(getQuery, ...)
///   DelegateOperation(setDocument,  ...)
///   DelegateOperation(deleteDocument,  ...)
/// ]
/// // first batch to execute will contain getDocument and getQuery
/// // second batch will contain setDocument
/// // third batch will contain deleteDocument
/// ```
class LockingStorageDelegate implements StorageDelegate {
  StorageDelegate delegate;

  @protected
  final List<DelegateOperation> transactionQueue = [];

  @protected
  final List<DelegateOperation> transactionsBeingProcessed = [];

  LockingStorageDelegate(this.delegate);

  /// USE WITH CAUTION !!!
  ///
  /// Replaces a delegate during instance lifetime.
  ///
  /// If there are pending operations in the operation queue,
  /// there may be unexpected behavior, because pending operations will be
  /// executed against new delegate.
  @protected
  replaceDelegate(StorageDelegate delegate) {
    this.delegate = delegate;
  }

  /// takes one or more operation from [transactionQueue] and keeps executing
  /// until the queue is empty
  ///
  /// if the first operation in the queue "canBePerformedInParallel"
  /// it will execute it in parallel with all the following operations
  /// which "canBePerformedInParallel". it will stop adding operations
  /// from the [transactionQueue] to the [transactionsBeingProcessed] when
  /// reaches a first operation which is not "canBePerformedInParallel"
  /// ```
  /// _operationQueue = [
  ///   DelegateOperation(getDocument, canBePerformedInParallel: true, ...)
  ///   DelegateOperation(getQuery, canBePerformedInParallel: true, ...)
  ///   DelegateOperation(setDocument, canBePerformedInParallel: false, ...)
  ///   DelegateOperation(deleteDocument, canBePerformedInParallel: false, ...)
  /// ]
  /// // first batch will contain getDocument and getQuery
  /// // second batch will contain setDocument
  /// // third batch will contain deleteDocument
  /// ```
  @protected
  Future executeFromQueue() async {
    // if there are no operations in progress
    // and there are operations in the queue
    // perform next operation(s)
    if (transactionsBeingProcessed.isEmpty && transactionQueue.isNotEmpty) {
      transactionsBeingProcessed.add(transactionQueue.removeAt(0));
      // if the first operation canBePerformedInParallel
      // add all following "canBePerformedInParallel" operations from
      // the _operationQueue to the _operationsBeingProcessed
      if (transactionsBeingProcessed.last.canBePerformedInParallel) {
        while (transactionQueue.isNotEmpty &&
            transactionsBeingProcessed.first.canBePerformedInParallel) {
          transactionsBeingProcessed.add(transactionQueue.removeAt(0));
        }
      }

      // let's execute all operations in _operationsBeingProcessed list
      // and returns the result or the error to the completer
      final executeOperationsInParallel = Future.wait(
          transactionsBeingProcessed.map((operation) => operation
                  .performer()
                  .then(operation.completer.complete)
                  .catchError((error) {
                operation.completer.completeError(error);
                return null;
              })));

      await executeOperationsInParallel;

      transactionsBeingProcessed.clear();

      // finally call _executeFromQueue again to execute the next operation
      // if there are operations arrived while executing the current batch
      return executeFromQueue();
    }
  }

  @protected
  Future requestConcurrentOperation(Future Function() operation) {
    final completer = Completer();

    transactionQueue.add(DelegateOperation(
        completer: completer,
        canBePerformedInParallel: true,
        performer: operation));

    executeFromQueue();

    return completer.future;
  }

  @protected
  Future requestLockingOperation(Future Function() operation) {
    final completer = Completer();

    transactionQueue.add(DelegateOperation(
        completer: completer,
        canBePerformedInParallel: false,
        performer: operation));

    executeFromQueue();

    return completer.future;
  }

  @override
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.addDocument<ID, T>(
          collectionName: collectionName,
          documentData: documentData,
          documentId: documentId,
          options: options,
        )).then((r) => r);
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.deleteDocument<ID>(
        collectionName: collectionName,
        documentId: documentId,
        options: options));
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          {required String collectionName, required ID documentId}) {
    return requestConcurrentOperation(() => delegate.getDocument<ID, T>(
        collectionName: collectionName, documentId: documentId)).then((r) => r);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) {
    return requestConcurrentOperation(() => delegate.getQuery<ID, T>(query))
        .then((r) => r);
  }

  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    return requestLockingOperation(
        () => delegate.performOperation(operation, options: options));
  }

  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.performTransaction(
        transaction,
        doOperationsInParallel: doOperationsInParallel,
        options: options));
  }

  @override
  Future serviceRequest(String serviceName, params) {
    return requestLockingOperation(
        () => delegate.serviceRequest(serviceName, params));
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.setDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.updateDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }
}

class DelegateOperation {
  final Future Function() performer;
  final bool canBePerformedInParallel;
  final Completer completer;

  DelegateOperation({
    required this.performer,
    required this.canBePerformedInParallel,
    required this.completer,
  });
}
