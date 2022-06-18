import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

class DelayedStorage extends InMemoryStorage {
  Duration readDelay;
  Duration writeDelay;

  DelayedStorage({
    required Map<String, Map<String, dynamic>> cache,
    required this.readDelay,
    required this.writeDelay,
  }) : super(cache);

  @override
  @protected
  Future<DocumentSnapshot<ID, T>>
      internalAddDocument<ID extends Object?, T extends Object?>(
          {required String collectionName,
          required T documentData,
          ID? documentId,
          options = const StorageOptions()}) async {
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
      internalGetDocument<ID extends Object?, T extends Object?>(
          {required String collectionName,
          required ID documentId,
          options = const StorageOptions()}) async {
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
          Query<ID, T> query,
          [Converters<ID, T>? converters]) async {
    await Future.delayed(readDelay);

    return super.internalGetQuery(query, converters);
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
