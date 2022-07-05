import 'dart:async';

import 'package:stater/stater.dart';

final _idGeneratorMap = <Type, int>{};

abstract class StorageAdapter {
  late final String id;

  StorageAdapter({
    String? id,
  }) {
    if (id == null) {
      _idGeneratorMap.update(
        runtimeType,
        (value) => value + 1,
        ifAbsent: () => 0,
      );

      this.id = '$runtimeType${_idGeneratorMap[runtimeType]}';
    } else {
      this.id = id;
    }
  }

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
    options = const StorageOptions(),
  });

  Future performOperation(
    Operation operation, {
    options = const StorageOptions(),
  });

  Future performTransaction(
    Transaction transaction, {
    doOperationsInParallel = false,
    options = const StorageOptions(),
  });

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
