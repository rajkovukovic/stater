import 'dart:convert';

import 'operation.dart';
import 'operation_type.dart';

class OperationServiceRequest extends Operation {
  dynamic data;

  OperationServiceRequest({
    required this.data,
    super.timestamp,
  });

  @override
  get changeType => OperationType.serviceRequest;

  factory OperationServiceRequest.fromMap(Map<String, dynamic> map) {
    return OperationServiceRequest(
      data: map['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationServiceRequest.fromJson(String source) =>
      OperationServiceRequest.fromMap(json.decode(source));
}
