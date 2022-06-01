import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/transaction/operation.dart';
import 'package:stater/src/transaction/transaction.dart';

abstract class StorageDelegate {
  /// creates a new document
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>(
    String collection,
    T data, [
    ID? documentId,
  ]);

  /// deletes the document
  Future<void> deleteDocument<ID extends Object?>(
      String collectionName, ID documentId);

  /// Reads the document
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionName, ID documentId);

  /// Reads the document
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query);

  /// Notifies of document updates at this location.
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionName, ID documentId);

  /// Notifies of document updates at this location.
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(Query<ID, T> query);

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionName, ID documentId, T data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> updateDocument<ID extends Object?>(
      String collectionName, ID documentId, Map<String, Object?> data);

  Future performOperation(Operation operation) {
    if (operation is OperationCreate) {
      return addDocument(
          operation.collectionName, operation.data, operation.documentId);
    }

    if (operation is OperationDelete) {
      return deleteDocument(operation.collectionName, operation.documentId);
    }

    if (operation is OperationSet) {
      return setDocument(
          operation.collectionName, operation.documentId, operation.data);
    }

    if (operation is OperationUpdate) {
      return updateDocument(
          operation.collectionName, operation.documentId, operation.data);
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
