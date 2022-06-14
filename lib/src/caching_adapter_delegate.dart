import 'package:stater/stater.dart';

abstract class CachingStorageDelegate extends StorageDelegate {
  @override
  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) {
    if (operation is CreateOperation) {
      return addDocument(
        collectionName: operation.collectionName,
        documentData: operation.data,
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

    throw 'performOperation does not implement an action when '
        'operation type is ${operation.runtimeType}';
  }
}
