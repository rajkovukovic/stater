import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage_options.dart';
import 'package:stater/src/transaction/operation.dart';
import 'package:stater/src/transaction/transaction.dart';

abstract class StorageDelegate {
  /// creates a new document
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  });

  /// deletes the document
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  });

  /// Reads the document
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
  });

  /// Reads the document
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query);

  /// Notifies of document updates at this location.
  // Stream<DocumentSnapshot<ID, T>>
  //     documentSnapshots<ID extends Object?, T extends Object?>({
  //   required String collectionName,
  //   required ID documentId,
  //   options = const StorageOptions(),
  // });

  /// Notifies of document updates at this location.
  // Stream<QuerySnapshot<ID, T>>
  //     querySnapshots<ID extends Object?, T extends Object?>({
  //   required Query<ID, T> query,
  //   options = const StorageOptions(),
  // });

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  });

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  });

  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) {
    if (operation is OperationCreate) {
      return addDocument(
        collectionName: operation.collectionName,
        documentData: operation.data,
        documentId: operation.documentId,
        options: options,
      );
    }

    if (operation is OperationDelete) {
      return deleteDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        options: options,
      );
    }

    if (operation is OperationSet) {
      return setDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        documentData: operation.data,
        options: options,
      );
    }

    if (operation is OperationUpdate) {
      return updateDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        documentData: operation.data,
        options: options,
      );
    }

    throw 'performOperation does not implement an action when '
        'operation type is ${operation.runtimeType}';
  }

  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    // TODO: implement rollback in case of failure
    if (doOperationsInParallel) {
      return Future.wait(transaction.operations
          .map((operation) => performOperation(operation, options: options)));
    } else {
      for (var operation in transaction.operations) {
        await performOperation(
          operation,
          options: options,
        );
      }
    }
  }
}

abstract class CascadableStorageDelegate extends StorageDelegate {
  final String id;
  // final QueryMatcher doesMatchQuery;
  // final QueryCompareGenerator? generateCompareFromQuery;

  CascadableStorageDelegate({
    required this.id,
    // required this.doesMatchQuery,
    // this.generateCompareFromQuery,
  });
}
