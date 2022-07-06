import 'dart:async';

import 'package:stater/stater.dart';

/// Every operation (read and write) is added to queue.
/// Completing of each operation is controlled from outside, by calling one of
/// methods [performNextWriteOperation], [performNextReadOperation],
/// [performNextOperation].
///
/// Useful for testing.
class PuppetAdapter extends ProxyAdapter {
  final _operationQueue = <QueueOperation>[];
  final bool readOperationsSkipQueue;

  PuppetAdapter(
    StorageAdapter delegate, {
    String? id,
    this.readOperationsSkipQueue = false,
  }) : super(delegate, id: id);

  Future<void> _requestWriteCompleter() {
    final operation = QueueOperation(
        performer: () async {}, isReadOperation: false, completer: Completer());

    _operationQueue.add(operation);

    return operation.completer.future;
  }

  Future<void> _requestReadCompleter() {
    final operation = QueueOperation(
        performer: () async {}, isReadOperation: true, completer: Completer());

    _operationQueue.add(operation);

    return operation.completer.future;
  }

  int get pendingOperationsCount => _operationQueue.length;

  bool get hasPendingOperations => _operationQueue.isNotEmpty;

  void performOperationByIndex(int index) {
    if (index > _operationQueue.length - 1) {
      throw '_operationQueue is empty';
    }

    final operation = _operationQueue.removeAt(index);
    operation.completer.complete();
  }

  void performNextWriteOperation() {
    final index =
        _operationQueue.indexWhere((operation) => !operation.isReadOperation);
    if (index < 0) {
      throw _operationQueue.isEmpty
          ? '_operationQueue is empty'
          : '_operationQueue does not have any write operation';
    } else {
      performOperationByIndex(index);
    }
  }

  void performNextReadOperation() {
    final index =
        _operationQueue.indexWhere((operation) => operation.isReadOperation);
    if (index < 0) {
      throw _operationQueue.isEmpty
          ? '_operationQueue is empty'
          : '_operationQueue does not have any write operation';
    } else {
      performOperationByIndex(index);
    }
  }

  void performNextOperation() {
    if (_operationQueue.isNotEmpty) {
      performOperationByIndex(0);
    } else {
      throw '_operationQueue is empty';
    }
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    await _requestWriteCompleter();

    return delegate.addDocument(
        collectionName: collectionName,
        documentData: documentData,
        documentId: documentId,
        options: options);
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    await _requestWriteCompleter();

    return delegate.deleteDocument(
      collectionName: collectionName,
      documentId: documentId,
      options: options,
    );
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    await _requestReadCompleter();

    return delegate.getDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) async {
    await _requestReadCompleter();

    return delegate.getQuery(query, options: options);
  }

  @override
  Future<dynamic> performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    await _requestWriteCompleter();

    return delegate.performTransaction(
      transaction,
      doOperationsInParallel: doOperationsInParallel,
      options: options,
    );
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await _requestWriteCompleter();

    return delegate.setDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options);
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    await _requestWriteCompleter();

    return delegate.updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }

  @override
  Future serviceRequest(String serviceName, dynamic params) async {
    await _requestWriteCompleter();

    return delegate.serviceRequest(serviceName, params);
  }
}
