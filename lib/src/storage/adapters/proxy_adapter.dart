import 'package:stater/stater.dart';

/// Base class for all adapters that should be used in adapter composition
abstract class ProxyAdapter implements StorageAdapter {
  StorageAdapter delegate;

  ProxyAdapter({required this.delegate});

  @override
  String get id => delegate.id;

  @override
  set id(String id) => throw Exception('StorageAdapter.id field is final');

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    return delegate.addDocument(
        collectionName: collectionName,
        documentData: documentData,
        options: options);
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return delegate.deleteDocument(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return delegate.getDocument(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) {
    return delegate.getQuery(query, options: options);
  }

  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) {
    return performOperation(operation, options: options);
  }

  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return performTransaction(transaction,
        doOperationsInParallel: doOperationsInParallel, options: options);
  }

  @override
  Future serviceRequest(String serviceName, params) {
    return delegate.serviceRequest(serviceName, params);
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
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
  }) {
    return delegate.updateDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options);
  }
}
