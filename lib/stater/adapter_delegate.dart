import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';

abstract class AdapterDelegate<ID extends Object?, T extends Object?> {
  /// creates a new document
  Future<DocumentSnapshot<ID, T>> addDocument(String collectionPath, T doc);

  /// deletes the document
  Future<void> deleteDocument(String collectionPath, ID docId);

  /// Reads the document
  Future<DocumentSnapshot<ID, T>> getDocument(String collectionPath, ID docId);

  /// Reads the document
  Future<QuerySnapshot<ID, T>> getQuery(Query query);

  /// Notifies of document updates at this location.
  Stream<DocumentSnapshot<ID, T>> documentSnapshots(
      String collectionPath, ID docId);

  /// Notifies of document updates at this location.
  Stream<QuerySnapshot<ID, T>> querySnapshots(Query query);

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> set(String collectionPath, ID docId, T data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(
      String collectionPath, ID docId, Map<String, Object?> data);
}
