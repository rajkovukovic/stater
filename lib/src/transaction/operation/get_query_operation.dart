import 'dart:convert';

import 'package:stater/stater.dart';

/// Gets data by a query
class GetQueryOperation extends CollectionOperation with ReadOperation {
  final Query query;

  GetQueryOperation({
    required super.collectionName,
    super.completer,
    required this.query,
    super.timestamp,
  });

  @override
  get operationType => OperationType.getQuery;

  @override
  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'operationType': operationType.name,
    };
  }

  @override
  String toJson() => json.encode(toMap());
}
