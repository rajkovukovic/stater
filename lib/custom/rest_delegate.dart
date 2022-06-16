import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

class RestDelegate extends CascadableStorageDelegate {
  RestDelegate({
    required this.endpoint,
    required super.id,
  });

  static const String idKey = '_id';
  static final requestOptions =
      Options(receiveTimeout: 5000, sendTimeout: 5000);

  final String endpoint;

  @override
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    if (documentId != null) {
      documentData = <String, dynamic>{
        if (documentData != null) ...(documentData as Map),
        idKey: documentId,
      } as T;
    }

    return Dio()
        .post('$endpoint/$collectionName',
            data: documentData, options: requestOptions)
        .then((response) {
      final data = response.data;
      final id = data[idKey] ?? '';
      return DocumentSnapshot(
        id,
        data,
        DocumentReference(
            collectionName: collectionName, documentId: id, delegate: this),
      );
    });
  }

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return Dio().delete('$endpoint/$collectionName/$documentId',
        options: requestOptions);
  }

  // @override
  // Stream<DocumentSnapshot<ID, T>>
  //     documentSnapshots<ID extends Object?, T extends Object?>(
  //         String collectionName, ID documentId) {
  //   // TODO: make sure updates are emmited to the stream
  //   // TODO: maybe periodical refetching of data?
  //   return Stream.fromFuture(getDocument(collectionName, documentId));
  // }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
  }) async {
    return Dio()
        .get('$endpoint/$collectionName/$documentId', options: requestOptions)
        .then((response) => response.data);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, [
    Converters<ID, T>? converters,
  ]) async {
    // var fakeId = 'fake-rest' as ID;
    // return Future.value(QuerySnapshot([
    //   DocumentSnapshot(
    //     fakeId,
    //     {
    //       "_id": fakeId,
    //       "name": fakeId,
    //     } as T,
    //     DocumentReference(
    //       collectionName: query.collectionName,
    //       documentId: fakeId,
    //       delegate: this,
    //     ),
    //   )
    // ]));

    final queryParameters = <String, dynamic>{};

    for (var operation in query.compareOperations) {
      if (operation.compareOperator != CompareOperator.isEqualTo) {
        throw 'RestDelegate can work only with CompareOperator.isEqualTo';
      }

      queryParameters[operation.field.toString()] = operation.valueToCompareTo;
    }

    return Dio()
        .get('$endpoint/${query.collectionName}',
            queryParameters: queryParameters, options: requestOptions)
        .then(
          (response) => QuerySnapshot(
            (response.data['data'] as Iterable)
                .map(
                  (element) => DocumentSnapshot<ID, T>(
                    element?[idKey] as ID ?? '' as ID,
                    element,
                    DocumentReference(
                      collectionName: query.collectionName,
                      documentId: element?[idKey] as ID ?? '' as ID,
                      delegate: this,
                    ),
                  ),
                )
                .toList(),
          ),
        );
  }

  // @override
  // Stream<QuerySnapshot<ID, T>>
  //     querySnapshots<ID extends Object?, T extends Object?>(
  //         Query<ID, T> query) {
  //   return Stream.fromFuture(getQuery(query));
  // }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
    Converters<ID, T>? converters,
  }) async {
    // return Future.value();

    return Dio()
        .put('$endpoint/$collectionName/$documentId',
            data: documentData, options: requestOptions)
        .then((response) => response.data);
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    return Dio()
        .patch('$endpoint/$collectionName/$documentId',
            data: documentData, options: requestOptions)
        .then((response) => response.data);
  }

  @override
  Future serviceRequest(String serviceName, dynamic params) async {
    switch (serviceName) {
      case 'createManyTodos':
        final int createCount = params;

        final Iterable<Map<String, dynamic>> existingTodos = await Dio()
            .get('$endpoint/todos')
            .then((response) => response.data);

        final existingNames = existingTodos.fold<Set<String>>(
            {},
            (acc, todo) =>
                acc..add(todo['name'].replaceAll(RegExp(r"\s+"), "")));

        int nextTodoNumber = 1;

        for (var i = 0; i < createCount; i++) {
          while (existingNames.contains('todo$nextTodoNumber')) {
            nextTodoNumber++;
          }

          final todo = {'name': 'Todo $nextTodoNumber', 'completed': false};

          await addDocument(
            collectionName: 'todos',
            documentData: todo,
            documentId: const Uuid().v4(),
          );

          nextTodoNumber++;
        }

        break;
      default:
        throw 'RestDelegate does not support serviceRequest "$serviceName"';
    }
  }
}
