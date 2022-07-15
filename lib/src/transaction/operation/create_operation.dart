import 'dart:async';
import 'dart:convert';

import 'collection_operation.dart';
import 'operation_type.dart';

/// Creates a document in a collection
class CreateOperation extends CollectionOperation {
  final String? documentId;
  Map<String, dynamic> data;

  CreateOperation({
    super.completer,
    this.documentId,
    required this.data,
    required super.collectionName,
    super.timestamp,
  });

  @override
  get operationType => OperationType.create;

  factory CreateOperation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    return CreateOperation(
      completer: completer,
      documentId: map['documentId'],
      collectionName: map['collectionName'],
      data: map['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'operationType': operationType.name,
      'collectionName': collectionName,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory CreateOperation.fromJson(String source) =>
      CreateOperation.fromMap(json.decode(source));
}
