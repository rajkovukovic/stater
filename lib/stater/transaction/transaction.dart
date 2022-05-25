import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'operation.dart';

class Transaction {
  final List<Operation> operations;
  final String id;

  Transaction(this.operations, {String? id}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'operations': operations.map((x) => x.toMap()).toList(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      List<Operation>.from(map['operations']?.map((x) => Operation.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));
}
