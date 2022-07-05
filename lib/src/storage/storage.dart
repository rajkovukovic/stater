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
        'classes derived from Storage should implement serviceRequest '
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
  final LockingStrategy lockingStrategy = WritesOneByOneReadsInParallel();

  /// defines this storage availability
  AvailabilityStrategy? availabilityStrategy;

  /// defines this storage retry strategy,
  /// used when a transaction fails on a first try
  RetryStrategy? retryStrategy;

  StreamSubscription? _availabilityStrategySubscription;

  /// has storage been initialized
  bool _isInit = false;

  bool _isAvailable = true;

  /// is this storage currently available for processing transactions
  bool get isAvailable => _isAvailable;

  /// initializes this storage by subscribing to the availabilityStrategy,
  /// if this storage has one.
  ///
  /// call destroy() method to remove subscription
  _init() {
    if (availabilityStrategy != null) {
      _isAvailable = availabilityStrategy!.isAvailable;
      _availabilityStrategySubscription =
          availabilityStrategy!.asStream.listen((nextValue) {
        final justBecameAvailable = !_isAvailable && nextValue;
        _isAvailable = nextValue;
        if (justBecameAvailable) {
          executeFromQueue();
        }
      });
    }
    _isInit = true;
  }

  /// queue of operations waiting to be processed
  @protected
  List<QueueOperation> operationsQueue = [];

  /// list of operations currently being processed.
  /// operations returned by LockingStrategy that are part of
  /// "executeAndSkipQueue" will not be added to this list.
  @protected
  final List<QueueOperation> operationsBeingProcessed = [];

  destroy() {
    _availabilityStrategySubscription?.cancel();
    // should we try to stop running transactions?
    operationsQueue.clear();
  }

  Storage get delegate => this;

  /// tries to execute next batch of operations from the queue<br>
  /// if this._isAvailable == true and lockingStrategy allows it
  @protected
  Future executeFromQueue() async {
    // init if not initialized already
    if (!_isInit) {
      _init();
    }

    // if storage is available and there are operations in the queue
    // perform next operation(s)
    if (_isAvailable && operationsQueue.isNotEmpty) {
      // let's find operations to process
      final operationsToProcess = lockingStrategy.findAvailableOperations(
        operationsBeingProcessed: operationsBeingProcessed,
        operationsQueue: operationsQueue,
      );

      // gather all operations that are about to start processing into a Set
      final operationsToProcessSet = {
        ...operationsToProcess.executeAndSkipQueue,
        ...operationsToProcess.nextBatch,
      };

      // remove all operations that are about to start processing from the queue
      operationsQueue = operationsQueue
          .where((operation) => !operationsToProcessSet.contains(operation))
          .toList();

      // start executing operations that are allowed to skip the queue
      for (var operation in operationsToProcess.executeAndSkipQueue) {
        operation.performWithRetry(retryStrategy);
      }

      // add nextBatch operations to the operationsQueue
      operationsQueue.addAll(operationsToProcess.nextBatch);

      // start executing nextBatch operations
      // and remove each of them from operationsQueue when completed
      for (var operation in operationsToProcess.nextBatch) {
        operation.performWithRetry(retryStrategy).whenComplete(() {
          operationsQueue.remove(operation);
          // process more operations from the queue
          // if LockingStrategy allows that
          executeFromQueue();
        });
      }
    }
  }

  /// adds a read operation to the queue.
  /// when this operation will start executing depends on:
  /// - storage availability
  /// - operations already in progress
  /// - and the lockingStrategy
  @protected
  Future requestReadOperation(
    Future Function() operation, [
    dynamic debugData,
  ]) {
    final completer = Completer();

    operationsQueue.add(QueueOperation(
        completer: completer,
        isReadOperation: true,
        performer: operation,
        debugData: debugData));

    executeFromQueue();

    return completer.future;
  }

  /// adds a write operation to the queue.
  /// when this operation will start executing depends on:
  /// - storage availability
  /// - operations already in progress
  /// - and the lockingStrategy
  @protected
  Future requestWriteOperation(
    Future Function() operation, [
    dynamic debugData,
  ]) {
    final completer = Completer();

    operationsQueue.add(QueueOperation(
        completer: completer,
        isReadOperation: false,
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
    return requestWriteOperation(
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
    return requestWriteOperation(() => delegate.internalDeleteDocument<ID>(
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
    return requestReadOperation(
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
    return requestReadOperation(
      () => delegate.internalGetQuery<ID, T>(query),
      {'caller': 'getQuery'},
    ).then((r) => r);
  }

  @nonVirtual
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    return requestWriteOperation(
        () => delegate.internalPerformOperation(operation, options: options));
  }

  @nonVirtual
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
      () => delegate.internalPerformTransaction(transaction,
          doOperationsInParallel: doOperationsInParallel, options: options),
      {'caller': 'performTransaction', 'transaction': transaction},
    );
  }

  @nonVirtual
  Future serviceRequest(String serviceName, params) {
    return requestWriteOperation(
        () => delegate.internalServiceRequest(serviceName, params));
  }

  @nonVirtual
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(() => delegate.internalSetDocument<ID, T>(
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
    return requestWriteOperation(() => delegate.internalUpdateDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options));
  }
}
