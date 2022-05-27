import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/transaction/operation.dart';

abstract class CachingAdapterDelegate extends AdapterDelegate {
  @override
  Future performOperation(Operation operation) {
    if (operation is OperationCreate) {
      return addDocument(operation.collectionPath, operation.data);
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
}
