import 'dart:async';
import 'dart:convert';

import 'operation.dart';

/// Performs a non standard CRUD operation
class ServiceRequestOperation extends Operation {
  dynamic params;
  String serviceName;

  ServiceRequestOperation({
    super.completer,
    required this.params,
    required this.serviceName,
    super.timestamp,
  });

  @override
  get operationType => OperationType.serviceRequest;

  factory ServiceRequestOperation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    return ServiceRequestOperation(
      params: map['params'],
      serviceName: map['serviceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'operationType': operationType.name,
      'params': params,
      'serviceName': serviceName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ServiceRequestOperation.fromJson(String source) =>
      ServiceRequestOperation.fromMap(json.decode(source));
}
