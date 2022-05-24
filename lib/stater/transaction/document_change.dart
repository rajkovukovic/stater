import 'dart:convert';

import 'package:flutter/foundation.dart';

enum DocumentChangeType {
  create,
  delete,
  set,
  update,
}

extension DocumentChangeTypeExtension on DocumentChangeType {
  String get name => describeEnum(this);
}

DocumentChangeType documentChangeTypeFromString(String s) {
  return DocumentChangeType.values.byName(s);
}

class DocumentChange {
  late final DateTime timestamp;
  final String collectionPath;
  final DocumentChangeType changeType;
  final Object? param;

  DocumentChange({
    DateTime? timestamp,
    required this.collectionPath,
    required this.changeType,
    required this.param,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'collectionPath': collectionPath,
      'changeType': changeType.toString(),
      'param': param,
    };
  }

  factory DocumentChange.fromMap(Map<String, dynamic> map) {
    return DocumentChange(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      collectionPath: map['collectionPath']!,
      changeType: documentChangeTypeFromString(map['changeType']),
      param: map['param'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DocumentChange.fromJson(String source) =>
      DocumentChange.fromMap(json.decode(source));
}
