import 'dart:async';
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

  factory GetQueryOperation.fromMap(
    Map<String, dynamic> map, {
    Completer? completer,
  }) {
    throw 'GetQueryOperation.fromMap() is not implemented';
    // return GetQueryOperation(
    //   completer: completer,
    //   query: Query.fromMap(map['query']),
    //   collectionName: map['collectionName'],
    //   timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    // );
  }

  @override
  Map<String, dynamic> toMap() {
    throw 'GetQueryOperation.toMap() is not implemented';
    // return {
    //   'operationType': operationType.name,
    //   'query': query.toMap(),
    //   'collectionName': collectionName,
    //   'timestamp': timestamp.millisecondsSinceEpoch,
    // };
  }

  factory GetQueryOperation.fromJson(String source) =>
      GetQueryOperation.fromMap(json.decode(source));
}
