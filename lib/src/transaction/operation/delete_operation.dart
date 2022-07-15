import 'dart:async';
import 'dart:convert';

import 'operation_type.dart';
import 'operation_with_document_id.dart';

/// Deletes a document from a collection
class DeleteOperation extends OperationWithDocumentId {
  DeleteOperation({
    super.completer,
    required super.documentId,
    required super.collectionName,
    super.timestamp,
  });

  @override
  get operationType => OperationType.delete;

  factory DeleteOperation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    return DeleteOperation(
      collectionName: map['collectionName'],
      documentId: map['documentId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'operationType': operationType.name,
      'collectionName': collectionName,
      'documentId': documentId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DeleteOperation.fromJson(String source) =>
      DeleteOperation.fromMap(json.decode(source));
}
