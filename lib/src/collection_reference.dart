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
    FromHashMap<ID, T>? fromHashMap,
    ToHashMap<T>? toHashMap,
  }) : super(
            delegate: delegate,
            collectionPath: collectionPath,
            fromHashMap: fromHashMap,
            toHashMap: toHashMap);

  Future<DocumentSnapshot<ID, T>?> add(T document, [ID? documentId]) =>
      delegate.addDocument(collectionPath, document, documentId);

  DocumentReference<ID, T> doc(ID documentId) {
    return DocumentReference<ID, T>(collectionPath, documentId, delegate);
  }
}
