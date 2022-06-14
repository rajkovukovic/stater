import 'dart:async';

import 'package:collection/collection.dart';
import 'package:stater/src/converters.dart';
import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';
import 'package:uuid/uuid.dart';

/// in-RAM StorageDelegate used for super fast operations
class InMemoryDelegate extends StorageDelegate {
  final Map<String, Map<String, dynamic>> _cache;

  InMemoryDelegate(Map<String, Map<String, dynamic>> cache) : _cache = cache;

  static FutureOr<InMemoryDelegate> fromClonedData(
    QuickStorageDelegate delegate,
  ) async {
    return InMemoryDelegate(await delegate.getAllData());
  }

  Map<String, Map<String, dynamic>> get data => _cache;

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

    collection?.remove(documentId);
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
      data,
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
        entry.value,
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
    final collection = _cache[collectionName];

    collection?[documentId.toString()] = documentData;
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
      collection?[documentId.toString()] = <String, Object?>{
        ...existing,
        ...documentData
      };
    }
  }
}

class InMemoryStorage extends Storage {
  InMemoryStorage([Map<String, Map<String, dynamic>>? cache])
      : super(InMemoryDelegate(cache ?? {}));

  InMemoryStorage.fromDelegate(InMemoryDelegate delegate) : super(delegate);

  static FutureOr<InMemoryStorage> fromClonedData(
    QuickStorageDelegate delegate,
  ) async {
    final cloned = await InMemoryDelegate.fromClonedData(delegate);
    return InMemoryStorage.fromDelegate(cloned);
  }
}
