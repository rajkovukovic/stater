import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

abstract class CachingDelegate {
  late Map<String, Map<String, dynamic>> data;

  late IMap<String, IMap<String, dynamic>> immutableData;
}

/// in-RAM StorageDelegate, usually used for data caching
class InMemoryStorage extends Storage implements CachingDelegate {
  IMap<String, IMap<String, dynamic>> _cache;

  InMemoryStorage(Map<String, Map<String, dynamic>> cache)
      : _cache = _dataFromMutableData(cache);

  InMemoryStorage.fromImmutableData(this._cache);

  // static FutureOr<InMemoryDelegate> fromClonedData(
  //   RootAccessStorage delegate,
  // ) async {
  //   return InMemoryDelegate(await delegate.getAllData());
  // }

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
    Query<ID, T> query, [
    Converters<ID, T>? converters,
  ]) async {
    final collection = _cache[query.collectionName];

    final docs = collection?.entries.mapIndexed((int index, entry) {
      return DocumentSnapshot<ID, T>(
        entry.key as ID,
        entry.value is IMap ? entry.value.unlockLazy : entry.value,
        DocumentReference<ID, T>(
          collectionName: query.collectionName,
          documentId: entry.key as ID,
          delegate: this,
          converters: converters,
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
      throw 'InMemoryDelegate.update: '
          'there is no doc to update (id=$documentId)';
    } else {
      _cache = _cache.add(
          collectionName,
          collection!.add(documentId.toString(),
              <String, Object?>{...existing, ...documentData}));
    }
  }
}

typedef ServiceRequestProcessor = Future Function(
    String serviceName, dynamic params);

typedef ServiceRequestProcessorFactory = ServiceRequestProcessor Function(
    Storage);

class LockingInMemoryDelegate extends LockingStorage
    implements CachingDelegate {
  LockingInMemoryDelegate(
    Map<String, Map<String, dynamic>> cache, {
    this.serviceRequestProcessorFactory,
  }) : super(InMemoryStorage(cache));

  @protected
  late ServiceRequestProcessorFactory? serviceRequestProcessorFactory;

  @protected
  late ServiceRequestProcessor? serviceRequestProcessor =
      serviceRequestProcessorFactory?.call(delegate);

  @override
  Future serviceRequest(String serviceName, params) {
    if (serviceRequestProcessor != null) {
      return serviceRequestProcessor!(serviceName, params);
    } else {
      return super.serviceRequest(serviceName, params);
    }
  }

  @override
  Map<String, Map<String, dynamic>> get data =>
      (delegate as InMemoryStorage).data;

  @override
  set data(Map<String, Map<String, dynamic>> value) {
    (delegate as InMemoryStorage).data = value;
  }

  @override
  IMap<String, IMap<String, dynamic>> get immutableData =>
      (delegate as InMemoryStorage).immutableData;

  @override
  set immutableData(IMap<String, IMap<String, dynamic>> value) {
    (delegate as InMemoryStorage).immutableData = value;
  }
}
