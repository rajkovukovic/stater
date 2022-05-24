import 'package:get_storage/get_storage.dart';
import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';

class GetStorageDelegate implements AdapterDelegate {
  GetStorageDelegate(this.storagePrefix);

  final String storagePrefix;

  GetStorage getStorage(String collectionName) =>
      GetStorage('$storagePrefix:$collectionName');

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T data) {
    throw UnimplementedError(
        'GetStorageDelegate does not support add method, use set method instead');
  }

  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId) async {
    final storage = GetStorage(storagePrefix);
    final stored = storage.read(collectionPath);

    final existing = stored == null
        ? <String, Object?>{}
        : Map<String, Object?>.from(stored);

    existing.remove(documentId);
    return storage.write(collectionPath, existing);
  }

  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    // TODO: make sure updates are emmited to the stream
    return Stream.fromFuture(getDocument(collectionPath, documentId));
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) async {
    final storage = getStorage(collectionPath);
    final stored = storage.read(collectionPath);

    final existing =
        stored == null ? <String, T>{} : Map<String, T>.from(stored);

    final snapshot = existing[documentId];
    return Future.value(DocumentSnapshot(
      documentId,
      snapshot,
      DocumentReference(collectionPath, documentId, this),
    ));
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) {
    // TODO: make sure updates are emmited to the stream
    throw UnimplementedError('GetStorageDelegate.getQuery is not implemented');
  }

  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(
          Query<ID, T> query) {
    return Stream.fromFuture(getQuery(query));
  }

  @override
  Future<void> set<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data) async {
    final storage = getStorage(collectionPath);
    final stored = storage.read(collectionPath);

    final existing =
        stored == null ? <String, T>{} : Map<String, T>.from(stored);

    existing[documentId.toString()] = data;
    storage.write(collectionPath, existing);
  }

  @override
  Future<void> update<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    final storage = getStorage(collectionPath);
    final stored = storage.read(collectionPath);

    final existing = stored == null
        ? <String, Object?>{}
        : Map<String, Object?>.from(stored);

    final oldValue = existing[documentId.toString()] as Map<String, dynamic>?;
    if (oldValue == null) {
      existing[documentId.toString()] = data;
    } else {
      oldValue.addAll(data);
      existing[documentId.toString()] = oldValue;
    }

    return storage.write(collectionPath, existing);
  }
}

class GetStorageAdapter extends Adapter {
  GetStorageAdapter(String storagePrefix)
      : super(GetStorageDelegate(storagePrefix));
}
