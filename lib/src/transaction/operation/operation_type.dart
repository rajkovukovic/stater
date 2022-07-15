import 'package:flutter/foundation.dart';

enum OperationType {
  create,
  delete,
  getDocument,
  getQuery,
  set,
  update,
  serviceRequest,
}

extension OperationTypeExtension on OperationType {
  String get name => describeEnum(this);
}

OperationType operationTypeFromString(String s) {
  return OperationType.values.byName(s);
}
