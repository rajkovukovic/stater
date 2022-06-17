import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

class GetStorageDelegate extends CascadableStorageDelegate
    implements QuickStorageDelegate {
  GetStorageDelegate({
    // required super.doesMatchQuery,
    // super.generateCompareFromQuery,
    required super.id,
    required this.storagePrefix,
  });

  final String storagePrefix;

  Future<GetStorage> _getExistingCollectionsBox() async {
    final storageName = '$storagePrefix:__internal__existingCollections__';

    await GetStorage.init(storageName);

    return GetStorage(storageName);
  }

  Future<Iterable<String>> _getExistingCollections() {
    return _getExistingCollectionsBox().then((box) => box.getKeys());
  }

  Future<void> _makeSureCollectionExists(String collection) async {
    final box = await _getExistingCollectionsBox();

    final existingCollections = Set.from(box.getKeys());
    if (!existingCollections.contains(collection)) {
      box.write(collection, true);
    }
  }

  Future<GetStorage> getCollectionBox(String collectionName) async {
    _makeSureCollectionExists(collectionName);

    final storageName = storagePrefix.isEmpty
        ? collectionName
        : '$storagePrefix:$collectionName';

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
    final storage = await getCollectionBox(collectionName);

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
    final storage = await getCollectionBox(collectionName);

    dynamic data = storage.read(documentId.toString());

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

    final storage = await getCollectionBox(collection);

    final keys = List<String>.from(storage.getKeys());

    var stored = (storage.getValues() as Iterable<dynamic>)
        .map((doc) => doc is String ? jsonDecode(doc) : doc);

    final docs = stored.mapIndexed((int index, dynamic doc) {
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
  }) async {
    final storage = await getCollectionBox(collectionName);

    storage.write(documentId.toString(), documentData);
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    final storage = await getCollectionBox(collectionName);
    final existing =
        storage.read(documentId.toString()) as Map<String, dynamic>?;

    if (existing == null) {
      throw 'GetStorageDelegate.update: there is no doc to update (id=$documentId)';
    } else {
      return storage.write(documentId.toString(),
          <String, Object?>{...existing, ...documentData});
    }
  }

  @override
  Future serviceRequest(String serviceName, dynamic params) async {
    switch (serviceName) {
      case 'createManyTodos':
        final int createCount = params;

        final Iterable<dynamic> existingTodos =
            (await getCollectionBox('todos')).getValues();

        final existingNames = existingTodos.fold<Set<String>>(
            {},
            (acc, todo) =>
                acc..add(todo['name'].replaceAll(RegExp(r"\s+"), "")));

        int nextTodoNumber = 1;

        for (var i = 0; i < createCount; i++) {
          while (existingNames.contains('todo$nextTodoNumber')) {
            nextTodoNumber++;
          }

          final todo = {'name': 'Todo $nextTodoNumber', 'completed': false};
          await addDocument(
            collectionName: 'todos',
            documentData: todo,
            documentId: const Uuid().v4(),
          );

          nextTodoNumber++;
        }
        break;
      default:
        throw 'RestDelegate does not support serviceRequest "$serviceName"';
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAllData() async {
    final existingCollections = List.from(await _getExistingCollections());

    final allData = await Future.wait(existingCollections
        .map((collectionName) => getCollectionData(collectionName)));

    return allData.foldIndexed<Map<String, Map<String, dynamic>>>({},
        (index, acc, cur) {
      acc[existingCollections[index]] = cur;
      return acc;
    });
  }

  @override
  Future<Map<String, dynamic>> getCollectionData(String collectionName) async {
    final storage = await getCollectionBox(collectionName);

    final keys = List<String>.from(storage.getKeys());

    var stored = (storage.getValues() as Iterable<dynamic>)
        .map((doc) => doc is String ? jsonDecode(doc) : doc);

    return stored.foldIndexed<Map<String, dynamic>>({}, (index, acc, cur) {
      acc[keys[index]] = cur;
      return acc;
    });
  }

  @override
  Future<void> insertData(Map<String, dynamic> collections) {
    return Future.wait(collections.entries
        .map((entry) => insertToCollection(entry.key, entry.value)));
  }

  @override
  Future<void> insertToCollection(
      String collectionName, Map<String, dynamic> documents) async {
    final storage = await getCollectionBox(collectionName);

    await storage.erase();

    return Future.wait(documents.entries
        .map((entry) => storage.write(entry.key, entry.value))).then((_) {});
  }

  @override
  Future<void> removeAllCollections() async {
    final existingCollections = await _getExistingCollections();

    return Future.wait(existingCollections.map(
        (collectionName) => removeCollection(collectionName))).then((_) {});
  }

  @override
  Future<void> removeAllDocumentsInCollection(String collectionName) async {
    final storage = await getCollectionBox(collectionName);

    await storage.erase();
  }

  @override
  Future<void> removeCollection(String collectionName) async {
    final clearCollection = removeAllDocumentsInCollection(collectionName);

    final removeCollectionName = _getExistingCollectionsBox().then((box) =>
        box.read(collectionName) == true ? box.remove(collectionName) : null);

    return Future.wait([clearCollection, removeCollectionName]).then((_) {});
  }

  @override
  Future<void> replaceCollection(
      String collectionName, Map<String, dynamic> documents) async {
    await removeAllDocumentsInCollection(collectionName);

    await insertToCollection(collectionName, documents);
  }
}
