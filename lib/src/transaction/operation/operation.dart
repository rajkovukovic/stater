import 'dart:async';
import 'dart:convert';

import 'package:stater/src/transaction/operation/get_document_operation.dart';
import 'package:stater/stater.dart';

export 'collection_operation.dart';
export 'create_operation.dart';
export 'delete_operation.dart';
export 'operation_type.dart';
export 'operation_with_document_id.dart';
export 'read_operation.dart';
export 'service_request_operation.dart';
export 'set_operation.dart';
export 'update_operation.dart';

/// abstract base Operation
///
/// all other Operations are derived from this class
abstract class Operation with HasNullableCompleter {
  late final DateTime timestamp;

  /// [completer] will be called when operation is successfully completed.
  /// [completer] will NOT be called in case of operation failure.
  Operation({
    Completer? completer,
    DateTime? timestamp,
  }) {
    this.completer = completer;
    this.timestamp = timestamp ?? DateTime.now();
  }

  OperationType get operationType;

  Map<String, dynamic> toMap();

  factory Operation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    final operationType = operationTypeFromString(map['operationType']);
    switch (operationType) {
      case OperationType.create:
        return CreateOperation.fromMap(map, completer: completer);

      case OperationType.delete:
        return DeleteOperation.fromMap(map, completer: completer);

      case OperationType.getDocument:
        return GetDocumentOperation.fromMap(map, completer: completer);

      case OperationType.getQuery:
        throw 'GetQueryOperation can not be created from a Map';
      // return GetQueryOperation.fromMap(map, completer: completer);

      case OperationType.set:
        return SetOperation.fromMap(map, completer: completer);

      case OperationType.update:
        return UpdateOperation.fromMap(map, completer: completer);

      case OperationType.serviceRequest:
        return ServiceRequestOperation.fromMap(map, completer: completer);

      default:
        throw 'Operation.fromMap does not have implemented $operationType';
    }
  }

  String toJson() => json.encode(toMap());
}
