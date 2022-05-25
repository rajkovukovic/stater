import 'dart:async';

import 'package:dio/dio.dart';
import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';

class RestDelegate extends AdapterDelegate {
  RestDelegate(this.endpoint);

  final String endpoint;

  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T data) {
    return Dio().post('$endpoint/$collectionPath', data: data).then((response) {
      final data = response.data;
      final id = data['id'] ?? '';
      return DocumentSnapshot(
        id,
        data,
        DocumentReference(collectionPath, id, this),
      );
    });
  }

  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId) {
    return Dio().delete('$endpoint/$collectionPath/$documentId');
  }

  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    // TODO: make sure updates are emmited to the stream
    // TODO: maybe periodical refetching of data?
    return Stream.fromFuture(getDocument(collectionPath, documentId));
  }

  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) async {
    return Dio()
        .get('$endpoint/$collectionPath/$documentId')
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
        .get('$endpoint/${query.collectionPath}',
            queryParameters: queryParameters)
        .then(
          (response) => QuerySnapshot(
            (response.data as Iterable)
                .map(
                  (element) => DocumentSnapshot<ID, T>(
                    element?['id'] as ID ?? '' as ID,
                    element,
                    DocumentReference(
                      query.collectionPath,
                      element?['id'] as ID ?? '' as ID,
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
      String collectionPath, ID documentId, T data) async {
    return Dio()
        .put('$endpoint/$collectionPath/$documentId', data: data)
        .then((response) => response.data);
  }

  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    return Dio()
        .patch('$endpoint/$collectionPath/$documentId', data: data)
        .then((response) => response.data);
  }
}

class RestAdapter extends Adapter {
  RestAdapter(String endpoint) : super(RestDelegate(endpoint));
}
