import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

/// in-RAM Storage, usually used for data caching
class InMemoryAdapter extends StorageAdapter
    implements StorageHasCache, StorageHasRootAccess {
  IMap<String, IMap<String, dynamic>> _cache;

  InMemoryAdapter(
    Map<String, Map<String, dynamic>> cache, {
    super.id,
  }) : _cache = _dataFromMutableData(cache);

  InMemoryAdapter.fromImmutableData(this._cache);

  static FutureOr<InMemoryAdapter> fromClonedData(
    StorageHasRootAccess delegate,
  ) async {
    return InMemoryAdapter(await delegate.getAllData());
  }

  static IMap<String, IMap<String, dynamic>> _dataFromMutableData(
          Map<String, Map<String, dynamic>> mutableData) =>
      IMap.fromEntries(
        mutableData.entries.map(
          ((collectionEntry) => MapEntry(
                collectionEntry.key,
                IMap.fromEntries(
                  collectionEntry.value.entries.map(
                    (docEntry) => MapEntry(docEntry.key,
                        docEntry is Map ? docEntry.value.lock : docEntry.value),
                  ),
                ),
              )),
        ),
      );

  @override
  Map<String, Map<String, dynamic>> get data =>
      Map.fromEntries(_cache.entries.map(
        (collectionEntry) => MapEntry(
          collectionEntry.key,
          Map.fromEntries(collectionEntry.value.entries.map(
            (docEntry) => MapEntry(
                docEntry.key,
                docEntry.value is IMap
                    ? docEntry.value.unlockLazy
                    : docEntry.value),
          )),
        ),
      ));

  @override
  set data(Map<String, Map<String, dynamic>> value) {
    _cache = _dataFromMutableData(value);
  }

  @override
  IMap<String, IMap<String, dynamic>> get immutableData => _cache;

  @override
  set immutableData(IMap<String, IMap<String, dynamic>> value) {
    _cache = value;
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    final notNullDocumentId = documentId ?? const Uuid().v4() as ID;

    return setDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
    ).then((_) => DocumentSnapshot(
          notNullDocumentId,
          documentData,
          DocumentReference(
            collectionName: collectionName,
            documentId: notNullDocumentId,
            delegate: this,
          ),
        ));
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    final collection = _cache[collectionName];

    if (collection != null && collection.containsKey(documentId.toString())) {
      _cache =
          _cache.add(collectionName, collection.remove(documentId.toString()));
    }
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    final collection = _cache[collectionName];

    dynamic data = collection?[documentId.toString()];

    return Future.value(DocumentSnapshot(
      documentId,
      data is IMap ? data.unlockLazy : data,
      DocumentReference(
        collectionName: collectionName,
        documentId: documentId,
        delegate: this,
      ),
    ));
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) async {
    final collection = _cache[query.collectionName];

    final docs = collection?.entries.mapIndexed((int index, entry) {
      return DocumentSnapshot<ID, T>(
        entry.key as ID,
        entry.value is IMap ? entry.value.unlockLazy : entry.value,
        DocumentReference<ID, T>(
          collectionName: query.collectionName,
          documentId: entry.key as ID,
          delegate: this,
          // converters: converters,
        ),
      );
    });

    return QuerySnapshot(docs?.toList() ?? []);
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    final collection = _cache[collectionName] ?? IMap();

    _cache = _cache.add(
        collectionName, collection.add(documentId.toString(), documentData));
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    final collection = _cache[collectionName];

    final existing = collection?[documentId.toString()];

    if (existing == null) {
      throw 'InMemoryAdapter.updateDocument: '
          'there is no doc to update (id=$documentId)';
    } else {
      _cache = _cache.add(
          collectionName,
          collection!.add(documentId.toString(),
              <String, Object?>{...existing, ...documentData}));
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAllData() {
    return Future.value(data);
  }

  @override
  Future serviceRequest(String serviceName, params) {
    throw 'InMemoryAdapter can not perform serviceRequest "$serviceName"';
  }

  @override
  Future<Map<String, dynamic>> getCollectionData(String collectionName) {
    // TODO: implement getCollectionData
    throw UnimplementedError();
  }

  @override
  Future<void> insertData(Map<String, dynamic> collections) {
    // TODO: implement insertData
    throw UnimplementedError();
  }

  @override
  Future<void> insertToCollection(
      String collectionName, Map<String, dynamic> documents) {
    // TODO: implement insertToCollection
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllCollections() {
    // TODO: implement removeAllCollections
    throw UnimplementedError();
  }

  @override
  Future<void> removeAllDocumentsInCollection(String collectionName) {
    // TODO: implement removeAllDocumentsInCollection
    throw UnimplementedError();
  }

  @override
  Future<void> removeCollection(String collectionName) {
    // TODO: implement removeCollection
    throw UnimplementedError();
  }

  @override
  Future<void> replaceCollection(
      String collectionName, Map<String, dynamic> documents) {
    // TODO: implement replaceCollection
    throw UnimplementedError();
  }
}

// class DelayedInMemoryAdapter extends InMemoryAdapter with DelayedStorageMixin {
//   DelayedInMemoryAdapter(
//     super.cache, {
//     Duration? readDelay,
//     Duration? writeDelay,
//     super.id,
//   }) {
//     this.readDelay = readDelay ?? this.readDelay;
//     this.writeDelay = writeDelay ?? this.writeDelay;
//   }
// }

typedef ServiceProcessor = Future Function(String serviceName, dynamic params);

typedef ServiceProcessorFactory = ServiceProcessor Function(Storage);
