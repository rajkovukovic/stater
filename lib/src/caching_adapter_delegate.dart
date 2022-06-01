import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/transaction/operation.dart';

abstract class CachingStorageDelegate extends StorageDelegate {
  @override
  Future performOperation(Operation operation) {
    if (operation is OperationCreate) {
      return addDocument(operation.collectionName, operation.data);
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
}
