import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

/// Completing of each operation is controlled from outside.
///
/// Useful for testing.
class PuppetStorage extends Storage with CascadableStorage {
  Storage internalStorage;

  PuppetStorage({
    required this.internalStorage,
    String? id,
  }) {
    final innerId = id == null
        ? internalStorage is CascadableStorage
            ? (internalStorage as CascadableStorage).id
            : const Uuid().v4()
        : null;

    this.id = id ?? 'puppetStorage@($innerId)';
  }

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
  @protected
  Future<DocumentSnapshot<ID, T>?>
      internalAddDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return internalStorage.addDocument(
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

    return internalStorage.deleteDocument(
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

    return internalStorage.getDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  @protected
  Future<QuerySnapshot<ID, T>>
      internalGetQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    // Converters<ID, T>? converters,
    StorageOptions options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return internalStorage.getQuery(query, options: options);
  }

  @override
  @protected
  Future<dynamic> internalPerformTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    await _requestCompleter();

    return internalStorage.performTransaction(
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

    return internalStorage.setDocument(
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

    return internalStorage.updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }

  @override
  @protected
  Future internalServiceRequest(String serviceName, dynamic params) async {
    await _requestCompleter();

    return internalStorage.serviceRequest(serviceName, params);
  }
}
