import 'dart:async';

import 'package:stater/stater.dart';

/// Completing of each operation is controlled from outside.
///
/// Useful for testing.
class PuppetAdapter extends ProxyAdapter {
  PuppetAdapter(StorageAdapter delegate) : super(delegate);

  final _completerQueue = <Completer>[];

  Future<void> _requestCompleter() {
    final completer = Completer();
    _completerQueue.add(completer);
    return completer.future;
  }

  int get pendingTransactionsCount => _completerQueue.length;

  bool get hasPendingTransactions => _completerQueue.isNotEmpty;

  void performNextTransaction() {
    if (_completerQueue.isEmpty) {
      throw 'Transaction Queue is empty';
    }

    final completer = _completerQueue.removeAt(0);
    completer.complete();
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

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
    await _requestCompleter();

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
    await _requestCompleter();

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
    await _requestCompleter();

    return delegate.getQuery(query, options: options);
  }

  @override
  Future<dynamic> performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

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
    await _requestCompleter();

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
    await _requestCompleter();

    return delegate.updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }

  @override
  Future serviceRequest(String serviceName, dynamic params) async {
    await _requestCompleter();

    return delegate.serviceRequest(serviceName, params);
  }
}
