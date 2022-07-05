import 'package:stater/src/transaction/operation/operation.dart';
import 'package:stater/src/transaction/transaction.dart';

class ExclusiveTransaction extends Transaction {
  final Set<String> excludeDelegateWithIds;

  ExclusiveTransaction({
    super.id,
    this.excludeDelegateWithIds = const {},
    required super.operations,
  });

  factory ExclusiveTransaction.fromMap(Map<String, dynamic> map) {
    return ExclusiveTransaction(
      id: map['id'],
      excludeDelegateWithIds: Set.from(map['excludeDelegateWithIds'] ?? []),
      operations: List<Operation>.from(
          map['operations']?.map((x) => Operation.fromMap(x))),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'excludeDelegateWithIds': excludeDelegateWithIds.toList(),
      'type': 'ExclusiveTransaction',
    };
  }

  @override
  ExclusiveTransaction copyWith({
    List<Operation>? operations,
    String? id,
    Set<String>? excludeDelegateWithIds,
  }) {
    return ExclusiveTransaction(
      operations: operations ?? this.operations,
      id: id ?? this.id,
      excludeDelegateWithIds:
          excludeDelegateWithIds ?? this.excludeDelegateWithIds,
    );
  }
}
