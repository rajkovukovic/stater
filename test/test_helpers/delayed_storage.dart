import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

/// Will delay every read operation for [readDelay]
/// and every write operation for [writeDelay]
///
/// Useful in testing. It is using InMemoryStorage under the hood.
class DelayedStorage extends InMemoryStorage with CascadableStorage {
  Duration readDelay;
  Duration writeDelay;

  DelayedStorage({
    required Map<String, Map<String, dynamic>> cache,
    required this.readDelay,
    required this.writeDelay,
    String id = 'delayedStorage',
  }) : super(cache) {
    this.id = id;
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
    /// await writeDelay already exist on internalSetDocument method
    /// which will be called eventually by super.internalAddDocument
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
    await Future.delayed(writeDelay);

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
    await Future.delayed(readDelay);

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
    await Future.delayed(readDelay);

    return super
        .internalGetQuery(query, converters: converters, options: options);
  }

  @override
  @protected
  Future<void> internalSetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(writeDelay);

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
    await Future.delayed(writeDelay);

    return super.internalUpdateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}
