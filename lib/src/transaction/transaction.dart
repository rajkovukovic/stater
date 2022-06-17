import 'dart:convert';

import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';


class Transaction {
  final List<Operation> operations;
  final String id;

  Transaction({String? id, required this.operations})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operations': operations.map((x) => x.toMap()).toList(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final transactionType = map['type'];

    switch (transactionType) {
      case 'ExclusiveTransaction':
        return ExclusiveTransaction.fromMap(map);

      case null:
        return Transaction(
          id: map['id'],
          operations: List<Operation>.from(
              map['operations']?.map((x) => Operation.fromMap(x))),
        );

      default:
        throw 'Transaction.fromMap does not have implemented '
            'Transaction of type "$transactionType"';
    }
  }

  static List<Transaction> fromListOfMap(Iterable<Map<String, dynamic>>? map) {
    return (map ?? []).map(Transaction.fromMap).toList();
  }

  static List<Map<String, dynamic>> toListOfMap(
      List<Transaction> transactions) {
    return transactions.map((transaction) => transaction.toMap()).toList();
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));
}
