import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/storage_delegate.dart';

import 'converters.dart';
import 'query.dart';

class CollectionReference<ID extends Object?, T extends Object?>
    extends Query<ID, T> {
  CollectionReference({
    required StorageDelegate delegate,
    required String collectionPath,
    FromStorage<ID, T>? fromStorage,
    ToStorage<T>? toStorage,
  }) : super(
            delegate: delegate,
            collectionPath: collectionPath,
            fromStorage: fromStorage,
            toStorage: toStorage);

  Future<DocumentSnapshot<ID, T>?> add(T document, [ID? documentId]) =>
      delegate.addDocument(collectionPath, document, documentId);

  DocumentReference<ID, T> doc(ID documentId) {
    return DocumentReference<ID, T>(collectionPath, documentId, delegate);
  }
}
