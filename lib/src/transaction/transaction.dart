import 'dart:convert';

import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

class Transaction with HasNullableCompleter {
  final String id;
  bool _isCompleted = false;
  final List<Operation> operations;

  Transaction({String? id, required this.operations})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operations': operations.map((x) => x.toMap()).toList(),
    };
  }

  Transaction cloneWithoutReadOperations() {
    return Transaction(
      id: id,
      operations:
          operations.where((operation) => operation is! ReadOperation).toList(),
    );
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
        throw 'Transaction.fromMap does not know hot to create '
            'a Transaction of type "$transactionType"';
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

  Transaction copyWith({
    List<Operation>? operations,
    String? id,
  }) {
    return Transaction(
      operations: operations ?? this.operations,
      id: id ?? this.id,
    );
  }

  bool get isCompleted => _isCompleted;

  bool get isNotCompleted => !isCompleted;

  /// calls completer method on each operation if exists,<br>
  /// then calls this.completer?.complete(results);
  complete({List? results, Object? withError}) {
    assert(
      (results == null) != (withError == null),
      'Transaction.complete must be called with only of one params '
      '[result, withError] being not null',
    );

    _isCompleted = true;

    if (results == null) {
      for (var i = 0; i < operations.length; i++) {
        operations[i].completer?.completeError(withError!);
      }

      completer?.completeError(withError!);
    } else {
      for (var i = 0; i < operations.length; i++) {
        operations[i].completer?.complete(results[i]);
      }

      completer?.complete(results);
    }
  }

  bool get hasOnlyReadOperations {
    return operations.every((operation) => operation is ReadOperation);
  }

  bool get hasOnlyWriteOperations {
    return operations.every((operation) => operation is! ReadOperation);
  }

  Transaction withoutReadOperations() {
    return copyWith(
        operations: operations
            .where((operation) => operation is! ReadOperation)
            .toList());
  }

  bool isEmpty() {
    return operations.isEmpty;
  }

  bool isNotEmpty() {
    return operations.isNotEmpty;
  }
}
