import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stater/src/converters.dart';
import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';
import 'package:uuid/uuid.dart';

class GetStorageDelegate extends StorageDelegateWithId {
  GetStorageDelegate({
    // required super.doesMatchQuery,
    // super.generateCompareFromQuery,
    required super.id,
    required this.storagePrefix,
  });

  final String storagePrefix;

  Future<GetStorage> getStorage(String collection) async {
    final storageName =
        storagePrefix.isEmpty ? collection : '$storagePrefix:$collection';

    await GetStorage.init(storageName);
    return GetStorage(storageName);
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
    final storage = await getStorage(collectionName);

    return storage.remove(documentId.toString());
  }

  // @override
  // Stream<DocumentSnapshot<ID, T>>
  //     documentSnapshots<ID extends Object?, T extends Object?>(
  //         String collection, ID documentId) {
  //   late StreamController<DocumentSnapshot<ID, T>> stream;
  //   Future<GetStorage>? storageFuture;
  //   void Function()? storageUnsubscriber;

  //   subscribe() async {
  //     storageFuture ??= getStorage(collection);
  //     final storage = await storageFuture!;
  //     storageUnsubscriber = storage.listenKey(documentId.toString(), (value) {
  //       stream.add(value);
  //     });
  //   }

  //   unsubscribe() async {
  //     await storageFuture;
  //     storageUnsubscriber?.call();
  //     storageUnsubscriber = null;
  //   }

  //   stream = StreamController(
  //       onListen: subscribe,
  //       onResume: subscribe,
  //       onCancel: unsubscribe,
  //       onPause: unsubscribe);

  //   return stream.stream;
  // }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    final storage = await getStorage(collectionName);
    final data = storage.read(documentId.toString());

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
    final collection = query.collectionName;

    final storage = await getStorage(collection);

    print(storage.getKeys());
    print(storage.getValues());

    final keys = List<String>.from(storage.getKeys());

    var stored = (storage.getValues() as Iterable<dynamic>).toList();

    final docs = stored.mapIndexed((int index, dynamic doc) {
      if (doc is String) {
        doc = jsonDecode(doc);
      }

      if (converters != null) {
        doc = converters.fromHashMap(
          DocumentSnapshot<ID, Map<String, dynamic>>(
              keys[index] as ID,
              doc,
              DocumentReference<ID, Map<String, dynamic>>(
                collectionName: query.collectionName,
                documentId: keys[index] as ID,
                delegate: this,
              )),
        );
      }

      return DocumentSnapshot<ID, T>(
        keys[index] as ID,
        doc,
        DocumentReference<ID, T>(
          collectionName: query.collectionName,
          documentId: keys[index] as ID,
          delegate: this,
          converters: converters,
        ),
      );
    });

    // print(docs.first);

    // docs = docs.where((element) => doesMatchQuery(element.data(), query));

    // if (docs.length > 1 && generateCompareFromQuery != null) {
    //   final compareFn = generateCompareFromQuery!(query);
    //   docs = docs.sorted(compareFn!);
    // }

    return QuerySnapshot(docs.toList());
  }

  // @override
  // Stream<QuerySnapshot<ID, T>>
  //     querySnapshots<ID extends Object?, T extends Object?>(
  //         Query<ID, T> query) {
  //   // TODO: make this updates are emitted to the stream
  //   return Stream.fromFuture(getQuery(query));
  // }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
    Converters<ID, T>? converters,
  }) async {
    final storage = await getStorage(collectionName);

    storage.write(
      documentId.toString(),
      converters != null ? converters.toHashMap(documentData) : documentData,
    );
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    final storage = await getStorage(collectionName);
    final existing =
        storage.read(documentId.toString()) as Map<String, dynamic>?;

    if (existing == null) {
      throw 'GetStorageDelegate.update: there is no doc to update (id=$documentId)';
    } else {
      return storage.write(documentId.toString(),
          <String, Object?>{...existing, ...documentData});
    }
  }
}

class GetStorageStorage extends Storage {
  GetStorageStorage(GetStorageDelegate delegate) : super(delegate);
}
