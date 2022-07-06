import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

/// Every operation (read and write) is added to queue.
/// Completing of each operation is controlled from outside, by calling one of
/// methods [performNextWriteOperation], [performNextReadOperation],
/// [performNextOperation].
///
/// Useful for testing.
class PuppetAdapter extends LockingAdapter {
  final bool readOperationsSkipQueue;

  PuppetAdapter(
    StorageAdapter delegate, {
    String? id,
    this.readOperationsSkipQueue = false,
  }) : super(
          delegate,
          id: id,
          lockingStrategy: PuppetLocking(),
        );

  PuppetLocking get puppetLocking => lockingStrategy as PuppetLocking;

  int get pendingOperationsCount => operationsQueue.length;

  bool get hasPendingOperations => operationsQueue.isNotEmpty;

  void performOperationByIndex(int index) {
    if (index < 0 || index > operationsQueue.length - 1) {
      throw 'index=($index) is out of range. '
          'There are ${operationsQueue.length} operations in the queue';
    }
    puppetLocking.performNext(operationsQueue.sublist(index, index + 1));
    executeFromQueue();
  }

  void performNextWriteOperation() {
    final index =
        operationsQueue.indexWhere((operation) => !operation.isReadOperation);

    if (index < 0) {
      throw operationsQueue.isEmpty
          ? 'operationsQueue is empty'
          : 'operationsQueue does not have any write operation';
    } else {
      performOperationByIndex(index);
    }
  }

  void performNextReadOperation() {
    final index =
        operationsQueue.indexWhere((operation) => operation.isReadOperation);

    if (index < 0) {
      throw operationsQueue.isEmpty
          ? 'operationsQueue is empty'
          : 'operationsQueue does not have any read operation';
    } else {
      performOperationByIndex(index);
    }
  }

  void performNextOperation() {
    if (operationsQueue.isNotEmpty) {
      performOperationByIndex(0);
    } else {
      throw 'operationsQueue is empty';
    }
  }

  @override
  @protected
  Future requestReadOperation(
    Future Function() operation, [
    dynamic debugData,
  ]) {
    /// make sure the operation is added to the queue
    final request = super.requestReadOperation(operation, debugData);

    if (readOperationsSkipQueue) {
      /// add the operation to the performNext queue
      puppetLocking.performNext([operationsQueue.last]);

      /// trigger execution from the queue
      executeFromQueue();
    }

    return request;
  }
}
