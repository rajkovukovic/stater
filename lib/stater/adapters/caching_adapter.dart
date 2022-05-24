import 'package:stater/stater/adapters/adapter.dart';
import 'package:stater/stater/transaction/transaction.dart';

abstract class CachingAdapter<ID extends Object?, T extends Object?>
    extends Adapter<ID, T> {
  bool get hasPendingTransactions;

  List<Transaction> get pendingTransactions;

  Future<void> clearPendingTransactions();

  Future<void> commitPendingTransactions({bool clearTransactionsOnSuccess});
}
