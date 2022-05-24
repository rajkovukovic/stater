import 'dart:convert';

import 'document_change.dart';

class Transaction {
  final List<DocumentChange> changes;

  Transaction(this.changes);

  Map<String, dynamic> toMap() {
    return {
      'changes': changes.map((x) => x.toMap()).toList(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      List<DocumentChange>.from(map['changes']?.map((x) => DocumentChange.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) => Transaction.fromMap(json.decode(source));
}
