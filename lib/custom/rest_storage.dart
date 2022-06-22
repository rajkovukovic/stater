import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

class RestStorage extends Storage with CascadableStorage {
  RestStorage({
    required this.endpoint,
    String? id,
  }) {
    this.id = id ?? 'restStorage@(${const Uuid().v4()})';
  }

  static const String idKey = 'id';

  final String endpoint;

  @override
  @protected
  Future<DocumentSnapshot<ID, T>?>
      internalAddDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) {
    if (documentId != null) {
      documentData = {
        if (documentData != null) ...(documentData as Map),
        idKey: documentId,
      } as T;
    }

    return http.post(
      Uri.parse('$endpoint/$collectionName'),
      body: jsonEncode(documentData),
      headers: {'content-type': 'application/json'},
    ).then((response) {
      final data = jsonDecode(response.body);
      if (data is! Map) {
        throw 'RestStorage.internalAddDocument expects response of type '
            'Map<String, dynamic>.\nGot "${data.runtimeType}" instead.';
      }
      final id = data[idKey] ?? '';
      return DocumentSnapshot(
        id,
        data as dynamic,
        DocumentReference(
            collectionName: collectionName, documentId: id, delegate: this),
      );
    });
  }

  @override
  @protected
  Future<void> internalDeleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    return http.delete(Uri.parse('$endpoint/$collectionName/$documentId'));
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
  @protected
  Future<DocumentSnapshot<ID, T>>
      internalGetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    final response =
        await http.get(Uri.parse('$endpoint/$collectionName/$documentId'));

    final data = jsonDecode(response.body);

    return DocumentSnapshot(
        documentId,
        data.cast<ID, T>(),
        DocumentReference(
            collectionName: collectionName,
            documentId: documentId,
            delegate: this));
  }

  @override
  @protected
  Future<QuerySnapshot<ID, T>>
      internalGetQuery<ID extends Object?, T extends Object?>(
    Query<ID, T> query, {
    Converters<ID, T>? converters,
    StorageOptions options = const StorageOptions(),
  }) async {
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

    final response = await http.get(
      Uri.parse('$endpoint/${query.collectionName}'
          '?q=${jsonEncode(queryParameters)}'),
      headers: {'content-type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    return QuerySnapshot(
      (data as Iterable)
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
    );
  }

  // @override
  @protected
  // Stream<QuerySnapshot<ID, T>>
  //     querySnapshots<ID extends Object?, T extends Object?>(
  //         Query<ID, T> query) {
  //   return Stream.fromFuture(getQuery(query));
  // }

  @override
  @protected
  Future<void> internalSetDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
    Converters<ID, T>? converters,
  }) async {
    await http.put(
      Uri.parse('$endpoint/$collectionName'),
      body: jsonEncode(documentData),
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  @protected
  Future<void> internalUpdateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    await http.patch(
      Uri.parse('$endpoint/$collectionName'),
      body: jsonEncode(documentData),
      headers: {'content-type': 'application/json'},
    );
  }

  @override
  @protected
  Future internalServiceRequest(String serviceName, dynamic params) async {
    return http.post(
      Uri.parse('$endpoint/api/serviceRequest/$serviceName'),
      body: jsonEncode(params),
      headers: {'content-type': 'application/json'},
    );
  }
}
