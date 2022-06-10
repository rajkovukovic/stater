import 'dart:convert';

import 'operation_type.dart';
import 'operation_with_document_id.dart';

/// Partially updates a document in a collection
///
/// ```
/// final todoBeforeUpdate = { 'name': 'Buy milk', 'completed': false }
///
/// final update = { 'completed': true }
///
/// final afterUpdate = { 'name': 'Buy milk', 'completed': true }
/// // property 'name' is preserved
/// ```
///
/// if you complete document overwrite, use SetOperation instead
class UpdateOperation extends OperationWithDocumentId {
  Map<String, dynamic> data;

  UpdateOperation({
    required this.data,
    required super.documentId,
    required super.collectionName,
    super.timestamp,
  });

  @override
  get changeType => OperationType.update;

  factory UpdateOperation.fromMap(Map<String, dynamic> map) {
    return UpdateOperation(
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

  factory UpdateOperation.fromJson(String source) =>
      UpdateOperation.fromMap(json.decode(source));
}
