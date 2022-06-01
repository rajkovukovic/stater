import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';

import 'query.dart';

class CollectionReference<ID extends Object?, T extends Object?>
    extends Query<ID, T> {
  CollectionReference({
    required StorageDelegate delegate,
    required String collectionName,
    options = const StorageOptions(),
  }) : super(
          delegate: delegate,
          collectionName: collectionName,
          options: options,
        );

  Future<DocumentSnapshot<ID, T>?> add(
    T document, {
    ID? documentId,
    options = const StorageOptions(),
  }) =>
      delegate.addDocument(
        collectionName: collectionName,
        documentData: document,
        documentId: documentId,
        options: options,
      );

  DocumentReference<ID, T> doc(ID documentId) {
    return DocumentReference<ID, T>(
      collectionName: collectionName,
      documentId: documentId,
      delegate: delegate,
      options: options,
    );
  }
}
