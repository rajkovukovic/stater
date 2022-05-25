import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:uuid/uuid.dart';

class GetStorageDelegate extends AdapterDelegate {
  GetStorageDelegate({
    required this.storagePrefix,
    this.doesMatchQuery,
    this.generateCompareFromQuery,
  });

  final String storagePrefix;
  final QueryMatcher? doesMatchQuery;
  final QueryCompareGenerator? generateCompareFromQuery;

  Future<GetStorage> getStorage(String collectionPath) async {
    final storageName = storagePrefix.isEmpty
        ? collectionPath
        : '$storagePrefix:$collectionPath';

    await GetStorage.init(storageName);
    return GetStorage(storageName);
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T data) {
    final documentId = const Uuid().v4() as ID;
    return setDocument(collectionPath, documentId, data)
        .then((_) => DocumentSnapshot(
          documentId,
          data,
          DocumentReference(collectionPath, documentId, this),
        ));
  }

  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId) async {
    final storage = await getStorage(collectionPath);

    return storage.remove(documentId.toString());
  }

  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    late StreamController<DocumentSnapshot<ID, T>> stream;
    Future<GetStorage>? storageFuture;
    void Function()? storageUnsubscriber;

    subscribe() async {
      storageFuture ??= getStorage(collectionPath);
      final storage = await storageFuture!;
      storageUnsubscriber = storage.listenKey(documentId.toString(), (value) {
        stream.add(value);
      });
    }

    unsubscribe() async {
      await storageFuture;
      storageUnsubscriber?.call();
      storageUnsubscriber = null;
    }

    stream = StreamController(
        onListen: subscribe,
        onResume: subscribe,
        onCancel: unsubscribe,
        onPause: unsubscribe);

    return stream.stream;
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) async {
    final storage = await getStorage(collectionPath);
    final data = storage.read(documentId.toString());

    return Future.value(DocumentSnapshot(
      documentId,
      data,
      DocumentReference(collectionPath, documentId, this),
    ));
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) async {
    final collectionPath = query.collectionPath;
    final storage = await getStorage(collectionPath);
    final keys = List<String>.from(storage.getKeys());
    var docs = (storage.getValues() as Iterable<dynamic>)
        .mapIndexed((index, doc) => DocumentSnapshot<ID, T>(
              keys[index] as ID,
              doc,
              DocumentReference(collectionPath, keys[index] as ID, this),
            ));

    if (doesMatchQuery != null) {
      docs = docs.where((element) => doesMatchQuery!(element.data(), query));

      if (docs.length > 1 && generateCompareFromQuery != null) {
        final compareFn = generateCompareFromQuery!(query);
        docs = docs.sorted(compareFn!);
      }
    }

    return QuerySnapshot(docs.toList());
  }

  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(
          Query<ID, T> query) {
    // TODO: make this updates are emitted to the stream
    return Stream.fromFuture(getQuery(query));
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data) async {
    final storage = await getStorage(collectionPath);

    storage.write(documentId.toString(), data);
  }

  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    final storage = await getStorage(collectionPath);
    final existing =
        storage.read(documentId.toString()) as Map<String, Object?>?;

    if (existing == null) {
      throw 'GetStorageDelegate.update: there is no doc to update (id=$documentId)';
    } else {
      return storage.write(
          documentId.toString(), <String, Object?>{...existing, ...data});
    }
  }
}

class GetStorageAdapter extends Adapter {
  GetStorageAdapter({
    String storagePrefix = '',
    QueryMatcher? doesMatchQuery,
    QueryCompareGenerator? generateCompareFromQuery,
  }) : super(
          GetStorageDelegate(
            storagePrefix: storagePrefix,
            doesMatchQuery: doesMatchQuery,
            generateCompareFromQuery: generateCompareFromQuery,
          ),
        );
}
