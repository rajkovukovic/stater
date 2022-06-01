import 'package:stater/src/cascade_storage/cascade_delegate.dart';
import 'package:stater/src/storage.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/transaction/transaction_storing_delegate.dart';

/// Storage that implements caching mechanism.
///
/// When performing a read/write operation,
/// it starts with first storage from adapters list
/// and goes through the list until one of the adapters succeeds,
/// or returns error of the last storage if all adapters fail.
class CascadeStorage<ID extends Object?> extends Storage {
  CascadeStorage({
    required StorageDelegateWithId primaryDelegate,
    required List<StorageDelegateWithId>? cachingDelegates,
    required TransactionStoringDelegate transactionStoringDelegate,
  }) : super(CascadeDelegate(
            primaryDelegate: primaryDelegate,
            cachingDelegates: cachingDelegates,
            transactionStoringDelegate: transactionStoringDelegate));
}
