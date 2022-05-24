import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

import 'rest_document_snapshot.dart';

class RestCollectionReference<ID extends Object?, T extends Object?>
    implements CollectionReference<ID, T> {
  final String endpoint;
  final String collectionPath;

  RestCollectionReference(this.endpoint, this.collectionPath);

  @override
  Future<DocumentReference<ID, T>> add(T data) {
    return http
        .post(
      Uri.parse('$endpoint/$collectionPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    )
        .then((response) {
      if (response.statusCode != 200) {
        throw response;
      }

      final body = jsonDecode(response.body);

      return RestDocumentReference(endpoint, body['id']);
    });
  }

  @override
  DocumentReference<ID, T> doc(ID documentId) {
    return RestDocumentReference(
        '$endpoint/$collectionPath', documentId.toString());
  }

  @override
  CollectionReference<ID, R> withConverter<R extends Object?>(
      {required FromRawDBEntry<ID, R> fromRaw,
      required ToRawDBEntry<R> toRaw}) {
    throw UnimplementedError();
  }

  @override
  Future<List<DocumentSnapshot<ID, T>>> get() {
    return http.get(Uri.parse('$endpoint/$collectionPath')).then((response) {
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body))
            .map((data) => RestDocumentSnapshot<ID, T>(
                id: data['id'] as ID,
                reference: RestDocumentReference(
                    '$endpoint/$collectionPath', data['id']),
                data: data as T))
            .cast<DocumentSnapshot<ID, T>>()
            .toList();
      } else {
        throw response.statusCode;
      }
    });
  }

  @override
  Stream<List<DocumentSnapshot<ID, T>>> snapshots() {
    return Stream.fromFuture(get());
  }
}
