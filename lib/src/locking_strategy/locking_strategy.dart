import 'package:stater/stater.dart';

/// Defines an availability strategy for a Storage.<br>
/// When [isAvailable] is true Storage will process transactions.<br>
/// When [isAvailable] is false Storage will pause processing of transactions.<br>
/// [asStream] getter should return a stream that emits a new value
/// representing new availability state.
abstract class LockingStrategy {
  LockingStrategyResult findAvailableOperations({
    required List<QueueOperation> operationsBeingProcessed,
    required List<QueueOperation> operationsQueue,
  });
}

class NeverLocks extends LockingStrategy {
  @override
  LockingStrategyResult findAvailableOperations({
    required List<QueueOperation> operationsBeingProcessed,
    required List<QueueOperation> operationsQueue,
  }) =>
      LockingStrategyResult(operationsQueue);
}

/// If the first operation in the queue is read operation
/// it will be executed in parallel with all the following read operations.
///
/// if the first operation in the queue is write operation,
/// the seconds operation in the queue will not start executing
/// until the first one is completed.
/// ```
/// operationsQueue = [
///   [getDocument]
///   [getQuery]
///   [setDocument]
///   [deleteDocument]
/// ]
/// // first batch will contain getDocument and getQuery
/// // second batch will contain setDocument only
/// // third batch will contain deleteDocument only
/// ```
class WritesOneByOneReadsInParallel extends LockingStrategy {
  @override
  LockingStrategyResult findAvailableOperations({
    required List<QueueOperation> operationsBeingProcessed,
    required List<QueueOperation> operationsQueue,
  }) {
    if (operationsBeingProcessed.isEmpty && operationsQueue.isNotEmpty) {
      int endIndex = 1;
      while (operationsQueue.first.isReadOperation &&
          endIndex < operationsQueue.length &&
          operationsQueue[endIndex].isReadOperation) {
        endIndex += 1;
      }
      return LockingStrategyResult(operationsQueue.sublist(0, endIndex));
    } else {
      return LockingStrategyResult.empty();
    }
  }
}

/// If we imagine multi-thread system, every read operation would get it's own
/// "thread" as soon as said read operation arrives to the queue.
///
/// All write operations would be sharing one single "thread" and a write
/// operation in the queue would be start executing when it's preceding
/// write operations is completed.
/// ```
/// operationsQueue = [
///   [updateDocument]
///   [getDocument]
///   [getQuery]
///   [setDocument]
///   [deleteDocument]
/// ]
/// // first batch will contain [updateDocument] only.
/// // [getDocument, getQuery] would start executing in parallel with the
/// // first batch and in parallel to each other
///
/// // second batch will contain [setDocument] only, no matter
/// // if read operations are completed or not
///
/// // third batch will contain [deleteDocument] only, no matter
/// // if read operations are completed or not
/// ```
class WritesOneByOneReadsSkipsTheQueue extends LockingStrategy {
  @override
  LockingStrategyResult findAvailableOperations({
    required List<QueueOperation> operationsBeingProcessed,
    required List<QueueOperation> operationsQueue,
  }) {
    final readOperations = operationsQueue
        .where((operation) => operation.isReadOperation)
        .toList();

    final nextWriteOperation = operationsBeingProcessed.isEmpty
        ? operationsQueue.cast<QueueOperation?>().firstWhere(
              (operation) => !operation!.isReadOperation,
              orElse: () => null,
            )
        : null;

    return LockingStrategyResult(
      nextWriteOperation == null ? [] : [nextWriteOperation],
      executeAndSkipQueue: readOperations,
    );
  }
}

/// Only one operation can be executed at the time,
/// no matter is it a read or a write operation
class EveryOperationLocks extends LockingStrategy {
  @override
  LockingStrategyResult findAvailableOperations({
    required List<QueueOperation> operationsBeingProcessed,
    required List<QueueOperation> operationsQueue,
  }) {
    if (operationsBeingProcessed.isEmpty && operationsQueue.isEmpty) {
      return LockingStrategyResult([operationsQueue.first]);
    } else {
      return LockingStrategyResult.empty();
    }
  }
}

class LockingStrategyResult {
  /// QueueOperation to be executed in the next step,
  /// will be added to the operationsBeingProcessed list
  final List<QueueOperation> nextBatch;

  /// QueueOperation to be executed in the next step,
  /// will **NOT** be added to the operationsBeingProcessed list
  final List<QueueOperation> executeAndSkipQueue;

  const LockingStrategyResult(this.nextBatch,
      {this.executeAndSkipQueue = const []});

  factory LockingStrategyResult.empty() {
    return const LockingStrategyResult([]);
  }
}
