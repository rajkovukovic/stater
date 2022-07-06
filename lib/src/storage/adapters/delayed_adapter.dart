import 'package:stater/stater.dart';

/// Delegates all calls to it's internalStorage with a delay.
///
/// Will delay every read operation for [readDelay]
/// and every write operation for [writeDelay].
///
/// Useful for testing.
class DelayedAdapter extends ProxyAdapter {
  Duration readDelay;
  Duration writeDelay;

  DelayedAdapter(
    StorageAdapter delegate, {
    super.id,
    required this.readDelay,
    required this.writeDelay,
  }) : super(delegate);

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    /// await writeDelay already exist on internalSetDocument method
    /// which will be called eventually by internalStorage.internalAddDocument
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
    await Future.delayed(writeDelay);

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
    await Future.delayed(readDelay);

    return delegate.getDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) async {
    await Future.delayed(readDelay);

    return delegate.getQuery(query, options: options);
  }

  // TODO: Don't override a method to do a super method invocation with the same parameters.
  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    print(null);
    return super.performTransaction(transaction,
        doOperationsInParallel: doOperationsInParallel, options: options);
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(writeDelay);

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
    await Future.delayed(writeDelay);

    return updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}
