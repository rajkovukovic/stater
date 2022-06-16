import 'package:stater/stater.dart';

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

  /// performs specific list of operations that can not be described using
  /// the existing CRUD operations
  Future serviceRequest(String serviceName, dynamic params) {
    throw 'classes derived from StorageDelegate should implement serviceRequest'
        'method. Did you forget to implement it?';
  }

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
    if (operation is CreateOperation) {
      return addDocument(
        collectionName: operation.collectionName,
        documentData: operation.data,
        documentId: operation.documentId,
        options: options,
      );
    }

    if (operation is DeleteOperation) {
      return deleteDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        options: options,
      );
    }

    if (operation is SetOperation) {
      return setDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        documentData: operation.data,
        options: options,
      );
    }

    if (operation is UpdateOperation) {
      return updateDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
        documentData: operation.data,
        options: options,
      );
    }

    if (operation is ServiceRequestOperation) {
      return serviceRequest(operation.serviceName, operation.params);
    }

    throw 'performOperation does not implement an action when '
        'operation type is ${operation.runtimeType}';
  }

  Future<dynamic> performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    // TODO: implement rollback in case of failure
    if (doOperationsInParallel) {
      return Future.wait(transaction.operations
          .map((operation) => performOperation(operation, options: options)));
    } else {
      final operationResults = [];
      for (var operation in transaction.operations) {
        operationResults.add(
          await performOperation(
            operation,
            options: options,
          ),
        );
      }
      return operationResults;
    }
  }
}
