import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

/// Implements AvailabilityStrategy, LockingStrategy and RetryStrategy.
/// Useful for making a composition of Adapters
class LockingAdapter extends ProxyAdapter {
  StreamSubscription? _availabilityStrategySubscription;

  bool _isAvailable = true;

  /// has storage been initialized
  bool _isInit = false;

  /// defines this storage availability
  AvailabilityStrategy? availabilityStrategy;

  /// rules for locking strategy
  /// i.e. we may want to lock access to storage while there is
  /// a write operation in progress
  late final LockingStrategy lockingStrategy;

  /// defines this storage retry strategy,
  /// used when a transaction fails on a first try
  RetryStrategy? retryStrategy;

  LockingAdapter(
    StorageAdapter delegate, {
    this.availabilityStrategy,
    super.id,
    LockingStrategy? lockingStrategy,
    this.retryStrategy,
  }) : super(delegate) {
    this.lockingStrategy = lockingStrategy ?? WritesOneByOneReadsInParallel();
  }

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

  /// if this._isAvailable == true and lockingStrategy allows
  /// it will try to execute next batch of operations from the queue<br>
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

      // add nextBatch operations to the operationsBeingProcessed
      operationsBeingProcessed.addAll(operationsToProcess.nextBatch);

      // start executing nextBatch operations
      // and remove each of them from operationsQueue when completed
      for (var operation in operationsToProcess.nextBatch) {
        operation.performWithRetry(retryStrategy).whenComplete(() {
          operationsBeingProcessed.remove(operation);
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

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
      () => delegate.addDocument<ID, T>(
        collectionName: collectionName,
        documentData: documentData,
        documentId: documentId,
        options: options,
      ),
      {
        'caller': 'addDocument',
        'collectionName': collectionName,
        'documentId': documentId,
        'documentData': documentData,
      },
    ).then((r) => r);
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
      () => delegate.deleteDocument<ID>(
          collectionName: collectionName,
          documentId: documentId,
          options: options),
      {
        'caller': 'deleteDocument',
        'collectionName': collectionName,
        'documentId': documentId,
      },
    );
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return requestReadOperation(
      () => delegate.getDocument<ID, T>(
          collectionName: collectionName, documentId: documentId),
      {
        'caller': 'getDocument',
        'collectionName': collectionName,
        'documentId': documentId,
      },
    ).then((r) => r);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    options = const StorageOptions(),
  }) {
    return requestReadOperation(
      () => delegate.getQuery<ID, T>(query),
      {
        'caller': 'getQuery',
        'query': query,
      },
    ).then((r) => r);
  }

  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    return requestWriteOperation(
        () => delegate.performOperation(operation, options: options), {
      'caller': 'performOperation',
      'operation': operation,
    });
  }

  @override
  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
      () => delegate.performTransaction(transaction,
          doOperationsInParallel: doOperationsInParallel, options: options),
      {'caller': 'performTransaction', 'transaction': transaction},
    );
  }

  @override
  Future serviceRequest(String serviceName, params) {
    return requestWriteOperation(
        () => delegate.serviceRequest(serviceName, params), {
      'caller': 'serviceRequest',
      'serviceName': serviceName,
      'params': params,
    });
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
        () => delegate.setDocument<ID, T>(
            collectionName: collectionName,
            documentId: documentId,
            documentData: documentData,
            options: options),
        {
          'caller': 'setDocument',
          'collectionName': collectionName,
          'documentId': documentId,
          'documentData': documentData,
        });
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) {
    return requestWriteOperation(
        () => delegate.updateDocument(
            collectionName: collectionName,
            documentId: documentId,
            documentData: documentData,
            options: options),
        {
          'caller': 'updateDocument',
          'collectionName': collectionName,
          'documentId': documentId,
          'documentData': documentData,
        });
  }
}
