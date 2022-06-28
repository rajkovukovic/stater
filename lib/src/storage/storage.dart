import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stater/src/transaction/operation/get_document_operation.dart';
import 'package:stater/src/transaction/operation/get_query_operation.dart';
import 'package:stater/stater.dart';

abstract class Storage {
  CollectionReference<ID, T> collection<ID extends Object?, T extends Object?>(
    String collectionName, {
    options = const StorageOptions(),
  }) {
    return CollectionReference(
      delegate: this,
      collectionName: collectionName,
      options: options,
    );
  }

  /// creates a new document
  @protected
  Future<DocumentSnapshot<ID, T>?>
      internalAddDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  });

  /// deletes the document
  @protected
  Future<void> internalDeleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  });

  /// Reads the document
  @protected
  Future<DocumentSnapshot<ID, T>>
      internalGetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  });

  /// Reads the document
  @protected
  Future<QuerySnapshot<ID, T>>
      internalGetQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    StorageOptions options = const StorageOptions(),
  });

  /// performs specific operation(s) that can not be described using
  /// the existing CRUD operations
  @protected
  Future internalServiceRequest(String serviceName, dynamic params) {
    throw Exception(
        'classes derived from StorageDelegate should implement serviceRequest '
        'method. Did you forget to implement it?\n'
        'Exception detected in class of type "$runtimeType"');
  }

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
  @protected
  Future<void> internalSetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  });

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @protected
  Future<void> internalUpdateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  });

  @protected
  Future internalPerformOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    final completer = Completer();
    dynamic operationResult;

    try {
      if (operation is CreateOperation) {
        operationResult = await internalAddDocument(
          collectionName: operation.collectionName,
          documentData: operation.data,
          documentId: operation.documentId,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is DeleteOperation) {
        await internalDeleteDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is GetDocumentOperation) {
        operationResult = await internalGetDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
        );

        return completer.complete(operationResult);
      }

      if (operation is GetQueryOperation) {
        operationResult = await internalGetQuery(operation.query);

        return completer.complete(operationResult);
      }

      if (operation is SetOperation) {
        await internalSetDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          documentData: operation.data,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is UpdateOperation) {
        await internalUpdateDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          documentData: operation.data,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is ServiceRequestOperation) {
        operationResult = await internalServiceRequest(
          operation.serviceName,
          operation.params,
        );

        return completer.complete(operationResult);
      }

      throw 'performOperation does not implement an action when '
          'operation type is ${operation.runtimeType}';
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      return Future.error(error);
    }
  }

  @protected
  Future<dynamic> internalPerformTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) async {
    // TODO: implement rollback in case of failure
    if (doOperationsInParallel) {
      return Future.wait(transaction.operations.map((operation) =>
          internalPerformOperation(operation, options: options)));
    } else {
      final operationResults = [];
      for (var operation in transaction.operations) {
        operationResults.add(
          await internalPerformOperation(
            operation,
            options: options,
          ),
        );
      }
      return operationResults;
    }
  }

  /// rules for locking strategy
  /// i.e. we may want to lock storage while there is
  /// a write operation in progress
  final LockingStrategy lockingStrategy = LockingStrategy.onlyWritingLocks;

  @protected
  final List<QueueOperation> transactionQueue = [];

  @protected
  final List<QueueOperation> transactionsBeingProcessed = [];

  destroy() {
    // should we try to stop running transactions?
    transactionQueue.clear();
  }

  Storage get delegate => this;

  /// takes one or more operation from [transactionQueue] and keeps executing
  /// until the queue is empty
  ///
  /// if the first operation in the queue "canBePerformedInParallel"
  /// it will execute it in parallel with all the following operations
  /// which "canBePerformedInParallel". it will stop adding operations
  /// from the [transactionQueue] to the [transactionsBeingProcessed] when
  /// reaches a first operation which is not "canBePerformedInParallel"
  /// ```
  /// _operationQueue = [
  ///   DelegateOperation(getDocument, canBePerformedInParallel: true, ...)
  ///   DelegateOperation(getQuery, canBePerformedInParallel: true, ...)
  ///   DelegateOperation(setDocument, canBePerformedInParallel: false, ...)
  ///   DelegateOperation(deleteDocument, canBePerformedInParallel: false, ...)
  /// ]
  /// // first batch will contain getDocument and getQuery
  /// // second batch will contain setDocument
  /// // third batch will contain deleteDocument
  /// ```
  @protected
  Future executeFromQueue() async {
    // if there are no operations in progress
    // and there are operations in the queue
    // perform next operation(s)
    if (transactionsBeingProcessed.isEmpty && transactionQueue.isNotEmpty) {
      transactionsBeingProcessed.add(transactionQueue.removeAt(0));
      // if the first operation canBePerformedInParallel
      // add all following "canBePerformedInParallel" operations from
      // the _operationQueue to the _operationsBeingProcessed
      if (transactionsBeingProcessed.last.canBePerformedInParallel) {
        while (transactionQueue.isNotEmpty &&
            transactionQueue.first.canBePerformedInParallel) {
          transactionsBeingProcessed.add(transactionQueue.removeAt(0));
        }
      }

      // let's execute all operations in _operationsBeingProcessed list
      // and returns the result or the error to the completer
      final executeOperationsInParallelFuture = Future.wait(
          transactionsBeingProcessed.map((operation) => operation
                  .performer()
                  .then(operation.completer.complete)
                  .catchError((error) {
                operation.completer.completeError(error);
                return null;
              })));

      await executeOperationsInParallelFuture;

      transactionsBeingProcessed.clear();

      // finally call _executeFromQueue again to execute the next operation
      // if there are operations arrived while executing the current batch
      return executeFromQueue();
    }
  }

  @protected
  Future requestConcurrentOperation(
    Future Function() operation, [
    dynamic debugData,
  ]) {
    final completer = Completer();

    transactionQueue.add(QueueOperation(
        completer: completer,
        canBePerformedInParallel: true,
        performer: operation,
        debugData: debugData));

    executeFromQueue();

    return completer.future;
  }

  @protected
  Future requestLockingOperation(
    Future Function() operation, [
    dynamic debugData,
  ]) {
    final completer = Completer();

    transactionQueue.add(QueueOperation(
        completer: completer,
        canBePerformedInParallel: false,
        performer: operation,
        debugData: debugData));

    executeFromQueue();

    return completer.future;
  }

  @nonVirtual
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(
        () => delegate.internalAddDocument<ID, T>(
              collectionName: collectionName,
              documentData: documentData,
              documentId: documentId,
              options: options,
            ),
        {'caller': 'addDocument'}).then((r) => r);
  }

  @nonVirtual
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.internalDeleteDocument<ID>(
        collectionName: collectionName,
        documentId: documentId,
        options: options));
  }

  @nonVirtual
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return requestConcurrentOperation(
      () => delegate.internalGetDocument<ID, T>(
          collectionName: collectionName, documentId: documentId),
      {'caller': 'getDocument'},
    ).then((r) => r);
  }

  @nonVirtual
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) {
    return requestConcurrentOperation(
      () => delegate.internalGetQuery<ID, T>(query),
      {'caller': 'getQuery'},
    ).then((r) => r);
  }

  @nonVirtual
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    return requestLockingOperation(
        () => delegate.internalPerformOperation(operation, options: options));
  }

  @nonVirtual
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(
      () => delegate.internalPerformTransaction(transaction,
          doOperationsInParallel: doOperationsInParallel, options: options),
      {'caller': 'performTransaction', 'transaction': transaction},
    );
  }

  @nonVirtual
  Future serviceRequest(String serviceName, params) {
    return requestLockingOperation(
        () => delegate.internalServiceRequest(serviceName, params));
  }

  @nonVirtual
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.internalSetDocument<ID, T>(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }

  @nonVirtual
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) {
    return requestLockingOperation(() => delegate.internalUpdateDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }
}

class QueueOperation {
  final Future Function() performer;
  final bool canBePerformedInParallel;
  final Completer completer;
  final dynamic debugData;

  QueueOperation({
    required this.performer,
    required this.canBePerformedInParallel,
    required this.completer,
    this.debugData,
  });
}

enum LockingStrategy {
  neverLocks,
  onlyWritingLocks,
  everyOperationLocks,
}
