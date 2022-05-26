import 'package:stater/stater/transaction/transaction.dart';

class ExclusiveTransaction extends Transaction {
  final Set<String> excludeDelegateWithIds;

  ExclusiveTransaction({
    this.excludeDelegateWithIds = const {},
    super.id,
    required super.operations,
  });
}
