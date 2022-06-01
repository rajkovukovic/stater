import 'package:meta/meta.dart';
import 'package:stater/stater/storage_delegate.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';
import 'package:stater/stater/document_snapshot.dart';

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
