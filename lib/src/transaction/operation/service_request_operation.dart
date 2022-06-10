import 'dart:convert';

import 'operation.dart';

/// Performs a non standard CRUD operation
class ServiceRequestOperation extends Operation {
  dynamic data;
  String serviceName;

  ServiceRequestOperation({
    required this.data,
    required this.serviceName,
    super.timestamp,
  });

  @override
  get changeType => OperationType.serviceRequest;

  factory ServiceRequestOperation.fromMap(Map<String, dynamic> map) {
    return ServiceRequestOperation(
      data: map['data'],
      serviceName: map['serviceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'data': data,
      'serviceName': serviceName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ServiceRequestOperation.fromJson(String source) =>
      ServiceRequestOperation.fromMap(json.decode(source));
}
