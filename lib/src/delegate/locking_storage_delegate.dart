import 'dart:async';

import 'package:stater/stater.dart';

class LockingStorageDelegate implements StorageDelegate {
  final StorageDelegate _delegate;

  final List<_DelegateOperation> _operationQueue = [];

  final List<_DelegateOperation> _operationsBeingProcessed = [];

  LockingStorageDelegate(StorageDelegate delegate) : _delegate = delegate;

  /// takes one or more operation from [_operationQueue] and keeps executing
  /// until the queue is empty
  ///
  /// if the first operation in the queue "canBePerformedInParallel"
  /// it will execute it in parallel with all the following operations
  /// which "canBePerformedInParallel". it will stop adding operations
  /// from the [_operationQueue] to the [_operationsBeingProcessed] when
  /// reaches a first operation which is not "canBePerformedInParallel"
  /// ```
  /// _operationQueue = [
  ///   _DelegateOperation(getDocument, canBePerformedInParallel: true, ...)
  ///   _DelegateOperation(getQuery, canBePerformedInParallel: true, ...)
  ///   _DelegateOperation(setDocument, canBePerformedInParallel: false, ...)
  ///   _DelegateOperation(deleteDocument, canBePerformedInParallel: false, ...)
  /// ]
  /// // first batch will contain getDocument and getQuery
  /// // second batch will contain setDocument
  /// // third batch will contain deleteDocument
  /// ```
  Future _executeFromQueue() async {
    // if there are no operations in progress
    // and there are operations in the queue
    // perform next operation(s)
    if (_operationsBeingProcessed.isEmpty && _operationQueue.isNotEmpty) {
      _operationsBeingProcessed.add(_operationQueue.removeAt(0));
      // if the first operation canBePerformedInParallel
      // add all following "canBePerformedInParallel" operations from
      // the _operationQueue to the _operationsBeingProcessed
      if (_operationsBeingProcessed.last.canBePerformedInParallel) {
        while (_operationQueue.isNotEmpty &&
            _operationsBeingProcessed.first.canBePerformedInParallel) {
          _operationsBeingProcessed.add(_operationQueue.removeAt(0));
        }
      }

      // let's execute all operations in _operationsBeingProcessed list
      // and returns the result or the error to the completer
      final executeOperationsInParallel = Future.wait(
          _operationsBeingProcessed.map((operation) => operation
                  .performer()
                  .then(operation.completer.complete)
                  .catchError((error) {
                operation.completer.completeError(error);
                return null;
              })));

      await executeOperationsInParallel;

      _operationsBeingProcessed.clear();

      // finally call _executeFromQueue again to execute the next operation
      // if there are operations arrived while executing the current batch
      return _executeFromQueue();
    }
  }

  Future _requestReadOperation(Future Function() operation) {
    final completer = Completer();

    _operationQueue.add(_DelegateOperation(
        completer: completer,
        canBePerformedInParallel: true,
        performer: operation));

    _executeFromQueue();

    return completer.future;
  }

  Future _requestWriteOperation(Future Function() operation) {
    final completer = Completer();

    _operationQueue.add(_DelegateOperation(
        completer: completer,
        canBePerformedInParallel: false,
        performer: operation));

    _executeFromQueue();

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
    return _requestWriteOperation(() => _delegate.addDocument<ID, T>(
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
    return _requestWriteOperation(() => _delegate.deleteDocument<ID>(
        collectionName: collectionName,
        documentId: documentId,
        options: options));
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          {required String collectionName, required ID documentId}) {
    return _requestReadOperation(() => _delegate.getDocument<ID, T>(
        collectionName: collectionName, documentId: documentId)).then((r) => r);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) {
    return _requestReadOperation(() => _delegate.getQuery<ID, T>(query))
        .then((r) => r);
  }

  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    return _requestWriteOperation(
        () => _delegate.performOperation(operation, options: options));
  }

  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return _requestWriteOperation(() => _delegate.performTransaction(
        transaction,
        doOperationsInParallel: doOperationsInParallel,
        options: options));
  }

  @override
  Future serviceRequest(String serviceName, params) {
    return _requestWriteOperation(
        () => _delegate.serviceRequest(serviceName, params));
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
    return _requestWriteOperation(() => _delegate.setDocument<ID, T>(
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
    return _requestWriteOperation(() => _delegate.updateDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }
}

class _DelegateOperation {
  final Future Function() performer;
  final bool canBePerformedInParallel;
  final Completer completer;

  _DelegateOperation({
    required this.performer,
    required this.canBePerformedInParallel,
    required this.completer,
  });
}
