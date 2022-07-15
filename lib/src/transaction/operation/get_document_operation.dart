import 'dart:async';
import 'dart:convert';

import 'package:stater/stater.dart';

/// Read a document from a collection
class GetDocumentOperation extends CollectionOperation with ReadOperation {
  final String documentId;

  GetDocumentOperation({
    required super.collectionName,
    super.completer,
    required this.documentId,
    super.timestamp,
  });

  @override
  get operationType => OperationType.getDocument;

  factory GetDocumentOperation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    return GetDocumentOperation(
      completer: completer,
      documentId: map['documentId'],
      collectionName: map['collectionName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'operationType': operationType.name,
      'collectionName': collectionName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory GetDocumentOperation.fromJson(String source) =>
      GetDocumentOperation.fromMap(json.decode(source));
}
