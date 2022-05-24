import 'package:get_storage/get_storage.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';

class GetStorageDelegate<ID extends Object?, T extends Object?>
    implements AdapterDelegate<ID, T> {
  GetStorageDelegate(this.name) : storage = GetStorage(name) {
    // storage.erase();
  }

  final String name;
  final GetStorage storage;

  @override
  Future<DocumentSnapshot<ID, T>> addDocument(String collectionPath, T doc) {
    // TODO: implement addDocument
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDocument(String collectionPath, ID documentId) async {
    final stored = storage.read(collectionPath);

    final existing =
        stored == null ? <String, T>{} : Map<String, T>.from(stored);

    existing.remove(documentId);
    return storage.write(collectionPath, existing);
  }

  @override
  Stream<DocumentSnapshot<ID, T>> documentSnapshots(
      String collectionPath, ID documentId) {
    // TODO: implement documentSnapshots
    throw UnimplementedError();
  }

  @override
  Future<DocumentSnapshot<ID, T>> getDocument(
      String collectionPath, ID documentId) async {
    // final stored = storage.read(collectionPath);

    // final existing =
    //     stored == null ? <String, T>{} : Map<String, T>.from(stored);

    // final snapshot = existing[documentId];
    // return Future.value(DocumentSnapshot(
    //   id: documentId,
    //   reference: this,
    //   data: snapshot,
    // ));
    throw UnimplementedError();
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery(Query<Object?, Object?> query) {
    // TODO: implement getQuery
    throw UnimplementedError();
  }

  @override
  Stream<QuerySnapshot<ID, T>> querySnapshots(Query<Object?, Object?> query) {
    // TODO: implement querySnapshots
    throw UnimplementedError();
  }

  @override
  Future<void> set(String collectionPath, ID documentId, T data) {
    // TODO: implement set
    throw UnimplementedError();
  }

  @override
  Future<void> update(
      String collectionPath, ID documentId, Map<String, Object?> data) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
