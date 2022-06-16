import 'dart:convert';

import 'operation.dart';

/// Performs a non standard CRUD operation
class ServiceRequestOperation extends Operation {
  dynamic params;
  String serviceName;

  ServiceRequestOperation({
    required this.params,
    required this.serviceName,
    super.timestamp,
  });

  @override
  get changeType => OperationType.serviceRequest;

  factory ServiceRequestOperation.fromMap(Map<String, dynamic> map) {
    return ServiceRequestOperation(
      params: map['params'],
      serviceName: map['serviceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'params': params,
      'serviceName': serviceName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ServiceRequestOperation.fromJson(String source) =>
      ServiceRequestOperation.fromMap(json.decode(source));
}
