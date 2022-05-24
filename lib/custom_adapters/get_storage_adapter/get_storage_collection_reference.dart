import 'package:get_storage/get_storage.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:uuid/uuid.dart';

import 'get_storage_document_reference.dart';
import 'get_storage_document_snapshot.dart';

const uuid = Uuid();

class GetStorageCollectionReference<ID extends Object?, T extends Object?>
    extends CollectionReference<ID, T> {
  final GetStorage storage;

  GetStorageCollectionReference({
    required this.storage,
    required super.collectionPath,
    required super.fromStorage,
    required super.toStorage,
  });

  @override
  Future<DocumentReference<ID, T>> add(T data) {
    final stored = storage.read(parameters['collectionPath']);

    final existing =
        stored == null ? <String, T>{} : Map<String, T>.from(stored);

    final documentId = uuid.v4();
    existing[documentId] = data;
    storage.write(parameters['collectionPath'], existing);
    return Future.value(GetStorageDocumentReference(
        storage: storage,
        collectionPath: parameters['collectionPath'],
        documentId: documentId as ID));
  }

  @override
  DocumentReference<ID, T> doc(ID documentId) {
    return GetStorageDocumentReference(
        storage: storage,
        collectionPath: parameters['collectionPath'],
        documentId: documentId);
  }

  @override
  CollectionReference<ID, R> withConverter<R extends Object?>(
      {required FromRawDBEntry<ID, R> fromRaw,
      required ToRawDBEntry<R> toRaw}) {
    throw UnimplementedError();
  }

  @override
  Future<QuerySnapshot<ID, T>> get() {
    final stored = storage.read(parameters['collectionPath']);

    final existing =
        stored == null ? <String, T>{} : Map<String, T>.from(stored);

    final existingConverted = existing.entries
        .map((entry) => GetStorageDocumentSnapshot<ID, T>(
            id: entry.key as ID,
            data: entry.value,
            reference: GetStorageDocumentReference(
                storage: storage,
                collectionPath: parameters['collectionPath'],
                documentId: entry.key as ID)))
        .toList();

    return Future.value(QuerySnapshot(existingConverted));
  }

  @override
  Stream<QuerySnapshot<ID, T>> snapshots() {
    return Stream.fromFuture(get());
  }
}
