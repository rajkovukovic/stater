import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';
import 'package:stater/src/transaction/operation.dart';

abstract class CachingStorageDelegate extends StorageDelegate {
  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) {
    if (operation is OperationCreate) {
      return addDocument(
        collectionName: operation.collectionName,
        documentData: operation.data,
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
}
