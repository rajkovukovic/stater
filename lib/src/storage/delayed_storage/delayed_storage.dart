import 'package:meta/meta.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

/// Delegates all calls to it's internalStorage with a delay.
///
/// Will delay every read operation for [readDelay]
/// and every write operation for [writeDelay].
///
/// Useful for testing.
class DelayedStorage extends Storage with CascadableStorage {
  Duration readDelay;
  Duration writeDelay;
  Storage internalStorage;

  DelayedStorage({
    required this.readDelay,
    required this.writeDelay,
    required this.internalStorage,
    String? id,
  }) {
    this.id = id ?? 'restStorage@(${const Uuid().v4()})';
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
    /// await writeDelay already exist on internalSetDocument method
    /// which will be called eventually by internalStorage.internalAddDocument
    return internalStorage.internalAddDocument(
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

    return internalStorage.internalDeleteDocument(
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

    return internalStorage.internalGetDocument<ID, T>(
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
    await Future.delayed(readDelay);

    return internalStorage.internalGetQuery(query, options: options);
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

    return internalStorage.internalSetDocument(
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

    return internalStorage.internalUpdateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}

mixin DelayedStorageMixin on CascadableStorage {
  Duration readDelay = Duration.zero;
  Duration writeDelay = Duration.zero;

  @override
  @protected
  Future<DocumentSnapshot<ID, T>?>
      internalAddDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    /// await writeDelay already exist on internalSetDocument method
    /// which will be called eventually by internalStorage.internalAddDocument
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
    // Converters<ID, T>? converters,
    StorageOptions options = const StorageOptions(),
  }) async {
    await Future.delayed(readDelay);

    return super.internalGetQuery(query, options: options);
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
