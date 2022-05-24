import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stater/stater/adapters/rest_adapter/rest_document_snapshot.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

class RestDocumentReference<ID extends Object?, T extends Object?>
    implements DocumentReference<ID, T> {
  final String endpoint;
  final String documentId;

  RestDocumentReference(this.endpoint, this.documentId);

  @override
  Future<void> delete() {
    return http.delete(Uri.parse('$endpoint/$documentId')).then((response) {
      if (response.statusCode != 200) {
        throw response.statusCode;
      }
    });
  }

  @override
  Future<DocumentSnapshot<ID, T>> get() {
    return http.get(Uri.parse('$endpoint/$documentId')).then((response) {
      if (response.statusCode == 200) {
        final parsed = Map<String, dynamic>.from(jsonDecode(response.body));
        return RestDocumentSnapshot(
            id: id, reference: this, data: parsed as dynamic);
      } else {
        throw response.statusCode;
      }
    });
  }

  @override
  ID get id => '$endpoint/$documentId' as ID;

  @override
  Future<void> set(T data) {
    return http
        .post(Uri.parse('$endpoint/$documentId'), body: data)
        .then((response) {
      if (response.statusCode != 200) {
        throw response.statusCode;
      }
    });
  }

  @override
  Stream<DocumentSnapshot<ID, T>> snapshots() {
    return Stream.fromFuture(get());
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    return http
        //     .patch(
        //   Uri.parse('$endpoint/$documentId'),
        //   headers: {'Content-Type': 'application/json'},
        //   body: jsonEncode(data),
        // )
        .put(
      Uri.parse('$endpoint/$documentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    )
        .then((response) {
      if (response.statusCode != 200) {
        throw response.statusCode;
      }
    });
  }
}
