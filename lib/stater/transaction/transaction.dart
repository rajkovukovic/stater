import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'operation.dart';

class Transaction {
  final List<Operation> operations;
  final String id;

  Transaction({String? id, required this.operations})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'operations': operations.map((x) => x.toMap()).toList(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      operations: List<Operation>.from(
          map['operations']?.map((x) => Operation.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));
}
