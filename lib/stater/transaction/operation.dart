import 'dart:convert';

import 'package:flutter/foundation.dart';

enum OperationType {
  create,
  delete,
  set,
  update,
}

extension OperationTypeExtension on OperationType {
  String get name => describeEnum(this);
}

OperationType operationTypeFromString(String s) {
  return OperationType.values.byName(s);
}

abstract class Operation {
  late final DateTime timestamp;
  final String collectionPath;

  Operation({
    DateTime? timestamp,
    required this.collectionPath,
  }) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  OperationType get changeType;

  Map<String, dynamic> toMap();

  factory Operation.fromMap(Map<String, dynamic> map) {
    final changeType = operationTypeFromString(map['changeType']);
    switch (changeType) {
      case OperationType.create:
        return OperationCreate.fromMap(map);
      case OperationType.delete:
        return OperationDelete.fromMap(map);
      case OperationType.set:
        return OperationSet.fromMap(map);
      case OperationType.update:
        return OperationUpdate.fromMap(map);
      default:
        throw 'Operation.fromMap does not have implemented $changeType';
    }
  }

  String toJson() => json.encode(toMap());
}

class OperationCreate extends Operation {
  final String? documentId;
  Map<String, dynamic> data;

  OperationCreate({
    this.documentId,
    required this.data,
    required super.collectionPath,
    super.timestamp,
  });

  @override
  get changeType => OperationType.create;

  factory OperationCreate.fromMap(Map<String, dynamic> map) {
    return OperationCreate(
      documentId: map['documentId'],
      collectionPath: map['collectionPath'],
      data: map['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'changeType': changeType.name,
      'collectionPath': collectionPath,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationCreate.fromJson(String source) =>
      OperationCreate.fromMap(json.decode(source));
}

abstract class OperationWithDocumentId extends Operation {
  final String documentId;

  OperationWithDocumentId({
    required this.documentId,
    super.timestamp,
    required super.collectionPath,
  });
}

class OperationDelete extends OperationWithDocumentId {
  OperationDelete({
    required super.documentId,
    required super.collectionPath,
    super.timestamp,
  });

  @override
  get changeType => OperationType.delete;

  factory OperationDelete.fromMap(Map<String, dynamic> map) {
    return OperationDelete(
      collectionPath: map['collectionPath'],
      documentId: map['documentId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'collectionPath': collectionPath,
      'documentId': documentId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationDelete.fromJson(String source) =>
      OperationDelete.fromMap(json.decode(source));
}

class OperationSet extends OperationWithDocumentId {
  Map<String, dynamic> data;

  OperationSet({
    required this.data,
    required super.documentId,
    required super.collectionPath,
    super.timestamp,
  });

  @override
  get changeType => OperationType.set;

  factory OperationSet.fromMap(Map<String, dynamic> map) {
    return OperationSet(
      collectionPath: map['collectionPath'],
      data: map['data'],
      documentId: map['documentId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'collectionPath': collectionPath,
      'data': data,
      'documentId': documentId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationSet.fromJson(String source) =>
      OperationSet.fromMap(json.decode(source));
}

class OperationUpdate extends OperationWithDocumentId {
  Map<String, dynamic> data;

  OperationUpdate({
    required this.data,
    required super.documentId,
    required super.collectionPath,
    super.timestamp,
  });

  @override
  get changeType => OperationType.update;

  factory OperationUpdate.fromMap(Map<String, dynamic> map) {
    return OperationUpdate(
      collectionPath: map['collectionPath'],
      data: map['data'],
      documentId: map['documentId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeType': changeType.name,
      'collectionPath': collectionPath,
      'data': data,
      'documentId': documentId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory OperationUpdate.fromJson(String source) =>
      OperationUpdate.fromMap(json.decode(source));
}
