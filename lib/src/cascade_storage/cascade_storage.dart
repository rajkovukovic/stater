import 'package:stater/src/cascade_storage/cascade_delegate.dart';
import 'package:stater/src/cascade_storage/json_query_matcher.dart';
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
    required CascadableStorageDelegate primaryDelegate,
    required List<CascadableStorageDelegate>? cachingDelegates,
    required TransactionStoringDelegate transactionStoringDelegate,
    JsonQueryMatcher? queryMatcher,
  }) : super(CascadeDelegate(
            primaryDelegate: primaryDelegate,
            cachingDelegates: cachingDelegates,
            transactionStoringDelegate: transactionStoringDelegate,
            queryMatcher: queryMatcher));
}
