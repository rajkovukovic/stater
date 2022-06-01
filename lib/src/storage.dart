import 'package:meta/meta.dart';
import 'package:stater/src/collection_reference.dart';
import 'package:stater/src/converters.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/storage_delegate.dart';

fromStorageIdentity(DocumentSnapshot snapshot) {
  return snapshot.data();
}

toStorageIdentity(Object? value) {
  return value;
}

class Storage {
  @protected
  final StorageDelegate delegate;

  Storage(this.delegate);

  CollectionReference<ID, T> collection<ID extends Object?, T extends Object?>(
    String path, {
    FromStorage<ID, T>? fromStorage,
    ToStorage<T>? toStorage,
  }) {
    return CollectionReference(
        delegate: delegate,
        collectionPath: path,
        fromStorage: fromStorage,
        toStorage: toStorage);
  }
}
