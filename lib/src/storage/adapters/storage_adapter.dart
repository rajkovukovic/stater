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

  void destroy() {}

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
    if (operation is CreateOperation) {
      return addDocument(
        collectionName: operation.collectionName,
        documentData: operation.data,
        documentId: operation.documentId,
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

    if (operation is GetDocumentOperation) {
      return getDocument(
        collectionName: operation.collectionName,
        documentId: operation.documentId,
      );
    }

    if (operation is GetQueryOperation) {
      return getQuery(operation.query);
    }

    if (operation is ServiceRequestOperation) {
      return await serviceRequest(
        operation.serviceName,
        operation.params,
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
