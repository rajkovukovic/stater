import 'dart:async';

import 'package:stater/src/transaction/operation/get_document_operation.dart';
import 'package:stater/src/transaction/operation/get_query_operation.dart';
import 'package:stater/stater.dart';

final _idGeneratorMap = <Type, int>{};

abstract class StorageAdapter {
  late final String _id;

  StorageAdapter({
    String? id,
  }) {
    if (id == null) {
      _idGeneratorMap.update(
        runtimeType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      _id = '$runtimeType-${_idGeneratorMap[runtimeType]}';
    } else {
      _id = id;
    }
  }

  String get id => _id;

  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  });

  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  });

  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  });

  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    StorageOptions options = const StorageOptions(),
  });

  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  }) async {
    final completer = Completer();
    dynamic operationResult;

    try {
      if (operation is CreateOperation) {
        operationResult = await addDocument(
          collectionName: operation.collectionName,
          documentData: operation.data,
          documentId: operation.documentId,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is DeleteOperation) {
        await deleteDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is GetDocumentOperation) {
        operationResult = await getDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
        );

        return completer.complete(operationResult);
      }

      if (operation is GetQueryOperation) {
        operationResult = await getQuery(operation.query);

        return completer.complete(operationResult);
      }

      if (operation is ServiceRequestOperation) {
        operationResult = await serviceRequest(
          operation.serviceName,
          operation.params,
        );

        return completer.complete(operationResult);
      }

      if (operation is SetOperation) {
        await setDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          documentData: operation.data,
          options: options,
        );

        return completer.complete(operationResult);
      }

      if (operation is UpdateOperation) {
        await updateDocument(
          collectionName: operation.collectionName,
          documentId: operation.documentId,
          documentData: operation.data,
          options: options,
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

  Future performTransaction(
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

  Future serviceRequest(String serviceName, params);

  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  });

  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  });
}
