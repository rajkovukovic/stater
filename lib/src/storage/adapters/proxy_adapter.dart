import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:stater/stater.dart';

/// Base class for all adapters that should be used in adapter composition
abstract class ProxyAdapter extends StorageAdapter
    implements StorageHasCache, StorageHasRootAccess {
  StorageAdapter delegate;

  ProxyAdapter(
    this.delegate, {
    super.id,
  });

  // @override
  // String get id => delegate.id;

  bool isComposedOf<T>() {
    StorageAdapter? nextDelegate = delegate;
    while (nextDelegate != null) {
      if (nextDelegate is T) {
        return true;
      }
      nextDelegate =
          nextDelegate is ProxyAdapter ? nextDelegate.delegate : null;
    }
    return false;
  }

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
    return delegate.performOperation(operation, options: options);
  }

  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return delegate.performTransaction(transaction,
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

  /// removes all documents and all collections
  @override
  Future<void> removeAllCollections() =>
      (delegate as StorageHasRootAccess).removeAllCollections();

  /// removes a collection and all its documents
  @override
  Future<void> removeCollection(String collectionName) =>
      (delegate as StorageHasRootAccess).removeCollection(collectionName);

  /// removes all documents from a collection,
  /// but leaves empty collection behind
  @override
  Future<void> removeAllDocumentsInCollection(String collectionName) =>
      (delegate as StorageHasRootAccess)
          .removeAllDocumentsInCollection(collectionName);

  /// inserts all [documents] to a collection and overwrites existing ones
  @override
  Future<void> insertToCollection(
    String collectionName,
    Map<String, dynamic> documents,
  ) =>
      (delegate as StorageHasRootAccess)
          .insertToCollection(collectionName, documents);

  /// removes all collection documents and inserts all from [documents] param
  @override
  Future<void> replaceCollection(
    String collectionName,
    Map<String, dynamic> documents,
  ) =>
      (delegate as StorageHasRootAccess)
          .replaceCollection(collectionName, documents);

  /// merges [collections] map into existing data
  ///
  /// existing documents will be overwritten
  @override
  Future<void> insertData(Map<String, dynamic> collections) =>
      (delegate as StorageHasRootAccess).insertData(collections);

  /// returns whole collection
  @override
  Future<Map<String, dynamic>> getCollectionData(String collectionName) =>
      (delegate as StorageHasRootAccess).getCollectionData(collectionName);

  /// returns whole database
  @override
  Future<Map<String, Map<String, dynamic>>> getAllData() =>
      (delegate as StorageHasRootAccess).getAllData();

  @override
  Map<String, Map<String, dynamic>> get data =>
      (delegate as StorageHasCache).data;

  @override
  set data(Map<String, Map<String, dynamic>> nextData) =>
      (delegate as StorageHasCache).data = nextData;

  @override
  IMap<String, IMap<String, dynamic>> get immutableData =>
      (delegate as StorageHasCache).immutableData;

  @override
  set immutableData(IMap<String, IMap<String, dynamic>> nextImmutableData) =>
      (delegate as StorageHasCache).immutableData = nextImmutableData;
}
