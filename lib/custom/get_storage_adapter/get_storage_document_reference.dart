import 'package:get_storage/get_storage.dart';
import 'package:stater/custom_adapters/get_storage_adapter/get_storage_document_snapshot.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

class GetStorageDocumentReference<ID extends Object?, T extends Object?>
    implements DocumentReference<ID, T> {
  final GetStorage storage;
  final String collectionPath;
  final ID documentId;

  GetStorageDocumentReference({
    required this.storage,
    required this.collectionPath,
    required this.documentId,
  });

  @override
  Future<void> delete() {
    try {
      final stored = storage.read(collectionPath);

      final existing =
          stored == null ? <String, T>{} : Map<String, T>.from(stored);

      existing.remove(documentId);
      return storage.write(collectionPath, existing);
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Future<DocumentSnapshot<ID, T>> get() {
    try {
      final stored = storage.read(collectionPath);

      final existing =
          stored == null ? <String, T>{} : Map<String, T>.from(stored);

      final snapshot = existing[documentId];
      return Future.value(GetStorageDocumentSnapshot(
        id: documentId,
        reference: this,
        data: snapshot,
      ));
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  ID get id => '$collectionPath/$documentId' as ID;

  @override
  Future<void> set(T data) {
    try {
      final stored = storage.read(collectionPath);

      final existing =
          stored == null ? <String, T>{} : Map<String, T>.from(stored);

      existing[documentId.toString()] = data;
      storage.write(collectionPath, existing);
      return Future.value();
    } catch (error) {
      return Future.error(error);
    }
  }

  @override
  Stream<DocumentSnapshot<ID, T>> snapshots() {
    return Stream.fromFuture(get());
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    try {
      final stored = storage.read(collectionPath);

      final existing =
          stored == null ? <String, T>{} : Map<String, T>.from(stored);

      final oldValue = existing[documentId.toString()] as Map<String, dynamic>?;
      if (oldValue == null) {
        existing[documentId.toString()] = data as T;
      } else {
        oldValue.addAll(data);
        existing[documentId.toString()] = oldValue as T;
      }

      return storage.write(collectionPath, existing).catchError((error) {
        print(error);
      });
    } catch (error) {
      return Future.error(error);
    }
  }
}
