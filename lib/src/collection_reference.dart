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
    StorageOptions options = const StorageOptions(),
  }) : super(
          delegate: delegate,
          collectionName: collectionName,
          options: options,
        );

  Future<DocumentSnapshot<ID, T>?> add(T document, [ID? documentId]) =>
      delegate.addDocument(collectionName, document, documentId);

  DocumentReference<ID, T> doc(ID documentId) {
    return DocumentReference<ID, T>(
      collectionName: collectionName,
      id: documentId,
      delegate: delegate,
      options: options,
    );
  }
}
