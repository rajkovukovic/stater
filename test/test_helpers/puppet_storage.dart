import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

/// Completing of each operation is controlled from outside.
///
/// Useful in testing. It is using InMemoryStorage under the hood.
class PuppetStorage extends InMemoryStorage with CascadableStorage {
  PuppetStorage({
    required Map<String, Map<String, dynamic>> cache,
    String id = 'puppetStorage',
  }) : super(cache) {
    this.id = id;
  }

  final _completerQueue = <Completer>[];

  Future<void> _requestCompleter() {
    final completer = Completer();
    _completerQueue.add(completer);
    return completer.future;
  }

  bool hasPendingTransactions() => _completerQueue.isNotEmpty;

  void performNextTransaction() {
    if (_completerQueue.isEmpty) {
      throw 'Transaction Queue is empty';
    }

    final completer = _completerQueue.removeAt(0);
    completer.complete();
  }

  @override
  @protected
  Future<DocumentSnapshot<ID, T>>
      internalAddDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalAddDocument(
        collectionName: collectionName,
        documentData: documentData,
        documentId: documentId,
        options: options);
  }

  @override
  @protected
  Future<void> internalDeleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalDeleteDocument(
      collectionName: collectionName,
      documentId: documentId,
      options: options,
    );
  }

  @override
  @protected
  Future<DocumentSnapshot<ID, T>>
      internalGetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalGetDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  @protected
  Future<QuerySnapshot<ID, T>>
      internalGetQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    Converters<ID, T>? converters,
    StorageOptions options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super
        .internalGetQuery(query, converters: converters, options: options);
  }

  @override
  @protected
  Future<dynamic> internalPerformTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalPerformTransaction(
      transaction,
      doOperationsInParallel: doOperationsInParallel,
      options: options,
    );
  }

  @override
  @protected
  Future<void> internalSetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalSetDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options);
  }

  @override
  @protected
  Future<void> internalUpdateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return super.internalUpdateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}
