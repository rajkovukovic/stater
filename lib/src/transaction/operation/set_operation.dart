import 'dart:convert';

import 'operation_type.dart';
import 'operation_with_document_id.dart';

/// Completely overwrites a document in a collection
///
/// ```
/// final todoBeforeUpdate = { 'name': 'Buy milk', 'completed': false }
///
/// final update = { 'completed': true }
///
/// final afterUpdate = { 'completed': true }
/// // property 'name' has been lost
/// ```
///
/// if you need a partial update, use UpdateOperation instead
class SetOperation extends OperationWithDocumentId {
  Map<String, dynamic> data;

  SetOperation({
    required this.data,
    required super.documentId,
    required super.collectionName,
    super.timestamp,
  });

  @override
  get changeType => OperationType.set;

  factory SetOperation.fromMap(Map<String, dynamic> map) {
    return SetOperation(
      collectionName: map['collectionName'],
      data: map['data'],
      documentId: map['documentId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'collectionName': collectionName,
      'data': data,
      'documentId': documentId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SetOperation.fromJson(String source) =>
      SetOperation.fromMap(json.decode(source));
}
