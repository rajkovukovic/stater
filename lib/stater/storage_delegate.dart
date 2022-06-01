import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:stater/stater/transaction/operation.dart';
import 'package:stater/stater/transaction/transaction.dart';

abstract class StorageDelegate {
  /// creates a new document
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T data,
          [ID? documentId]);

  /// deletes the document
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId);

  /// Reads the document
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId);

  /// Reads the document
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query);

  /// Notifies of document updates at this location.
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId);

  /// Notifies of document updates at this location.
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(Query<ID, T> query);

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data);

  Future performOperation(Operation operation) {
    if (operation is OperationCreate) {
      return addDocument(
          operation.collectionPath, operation.data, operation.documentId);
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

  Future performTransaction(Transaction transaction,
      [doOperationsInParallel = false]) async {
    // TODO: implement rollback in case of failure
    if (doOperationsInParallel) {
      return Future.wait(transaction.operations.map(performOperation));
    } else {
      for (var operation in transaction.operations) {
        await performOperation(operation);
      }
    }
  }
}

abstract class StorageDelegateWithId extends StorageDelegate {
  final String id;
  final QueryMatcher doesMatchQuery;
  final QueryCompareGenerator? generateCompareFromQuery;

  StorageDelegateWithId({
    required this.id,
    required this.doesMatchQuery,
    this.generateCompareFromQuery,
  });
}
