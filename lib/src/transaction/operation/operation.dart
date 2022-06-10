import 'dart:convert';

import 'create_operation.dart';
import 'delete_operation.dart';
import 'operation_type.dart';
import 'service_request_operation.dart';
import 'set_operation.dart';
import 'update_operation.dart';

export 'collection_operation.dart';
export 'create_operation.dart';
export 'delete_operation.dart';
export 'operation_type.dart';
export 'operation_with_document_id.dart';
export 'service_request_operation.dart';
export 'set_operation.dart';
export 'update_operation.dart';

/// abstract base Operation
///
/// all other Operations extend this class
abstract class Operation {
  late final DateTime timestamp;

  Operation({
    DateTime? timestamp,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  OperationType get changeType;

  Map<String, dynamic> toMap();

  factory Operation.fromMap(Map<String, dynamic> map) {
    final changeType = operationTypeFromString(map['changeType']);
    switch (changeType) {
      case OperationType.create:
        return CreateOperation.fromMap(map);
      case OperationType.delete:
        return DeleteOperation.fromMap(map);
      case OperationType.set:
        return SetOperation.fromMap(map);
      case OperationType.update:
        return UpdateOperation.fromMap(map);
      case OperationType.serviceRequest:
        return OperationServiceRequest.fromMap(map);
      default:
        throw 'Operation.fromMap does not have implemented $changeType';
    }
  }

  String toJson() => json.encode(toMap());
}
