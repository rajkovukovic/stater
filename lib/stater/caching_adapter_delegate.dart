import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:stater/stater/transaction/operation.dart';

abstract class CachingAdapterDelegate extends AdapterDelegate {
  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T data);

  /// deletes the document
  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId);

  /// Reads the document
  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId);

  /// Reads the document
  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query);

  /// Notifies of document updates at this location.
  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId);

  /// Notifies of document updates at this location.
  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(Query<ID, T> query);

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data);

  @override
  Future performOperation(Operation operation) {
    if (operation is OperationCreate) {
      return addDocument(operation.collectionPath, operation.data);
    }

    if (operation is OperationDelete) {
      return deleteDocument(operation.collectionPath, operation.documentId);
    }

    if (operation is OperationSet) {
      return setDocument(
          operation.collectionPath, operation.documentId, operation.data);
    }

    if (operation is OperationUpdate) {
      return updateDocument(
          operation.collectionPath, operation.documentId, operation.data);
    }

    throw 'performOperation does not implement an action when '
        'operation type is ${operation.runtimeType}';
  }
}
