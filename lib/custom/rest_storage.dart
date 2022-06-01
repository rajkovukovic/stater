import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage.dart';
import 'package:stater/src/storage_delegate.dart';

class RestDelegate extends StorageDelegateWithId {
  RestDelegate({
    required super.doesMatchQuery,
    required this.endpoint,
    required super.id,
  });

  static const String idKey = '_id';
  static final requestOptions =
      Options(receiveTimeout: 5000, sendTimeout: 5000);

  final String endpoint;

  @override
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionName, T data,
          [ID? documentId]) {
    if (documentId != null) {
      data = <String, dynamic>{
        if (data != null) ...(data as Map),
        idKey: documentId,
      } as T;
    }

    return Dio()
        .post('$endpoint/$collectionName', data: data, options: requestOptions)
        .then((response) {
      final data = response.data;
      final id = data[idKey] ?? '';
      return DocumentSnapshot(
        id,
        data,
        DocumentReference(collectionName, id, this),
      );
    });
  }

  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionName, ID documentId) {
    return Dio().delete('$endpoint/$collectionName/$documentId',
        options: requestOptions);
  }

  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionName, ID documentId) {
    // TODO: make sure updates are emmited to the stream
    // TODO: maybe periodical refetching of data?
    return Stream.fromFuture(getDocument(collectionName, documentId));
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionName, ID documentId) async {
    return Dio()
        .get('$endpoint/$collectionName/$documentId', options: requestOptions)
        .then((response) => response.data);
  }

  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) async {
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
                      query.collectionName,
                      element?[idKey] as ID ?? '' as ID,
                      this,
                    ),
                  ),
                )
                .toList(),
          ),
        );
  }

  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(
          Query<ID, T> query) {
    return Stream.fromFuture(getQuery(query));
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionName, ID documentId, T data) async {
    return Dio()
        .put('$endpoint/$collectionName/$documentId',
            data: data, options: requestOptions)
        .then((response) => response.data);
  }

  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionName, ID documentId, Map<String, Object?> data) async {
    return Dio()
        .patch('$endpoint/$collectionName/$documentId',
            data: data, options: requestOptions)
        .then((response) => response.data);
  }
}

class RestStorage extends Storage {
  RestStorage(RestDelegate delegate) : super(delegate);
}
