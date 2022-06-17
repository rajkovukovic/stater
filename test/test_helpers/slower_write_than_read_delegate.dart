import 'package:stater/stater.dart';

const _readDuration = Duration(milliseconds: 50);
const _writeDuration = Duration(milliseconds: 100);

class SlowerWriteThanReadDelegate extends InMemoryStorage {
  SlowerWriteThanReadDelegate(super.cache);

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          {required String collectionName,
          required T documentData,
          ID? documentId,
          options = const StorageOptions()}) async {
    return super.addDocument(
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
    await Future.delayed(_writeDuration);

    return super.deleteDocument(
      collectionName: collectionName,
      documentId: documentId,
      options: options,
    );
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          {required String collectionName,
          required ID documentId,
          options = const StorageOptions()}) async {
    await Future.delayed(_readDuration);

    return super.getDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        options: options);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query,
      [Converters<ID, T>? converters]) async {
    await Future.delayed(_readDuration);

    return super.getQuery(query, converters);
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(_writeDuration);

    return super.setDocument(
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
    await Future.delayed(_writeDuration);

    return super.updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}
