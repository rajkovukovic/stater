import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

class Storage<D extends StorageAdapter> {
  @protected
  late final D delegate;

  Storage(this.delegate);

  // /// defines this storage availability
  // AvailabilityStrategy? get availabilityStrategy =>
  //     delegate.availabilityStrategy;

  // /// is this storage currently available for processing transactions
  // bool get isAvailable => delegate.isAvailable;

  // /// rules for locking strategy
  // /// i.e. we may want to lock storage while there is
  // /// a write operation in progress
  // LockingStrategy get lockingStrategy => delegate.lockingStrategy;

  // /// defines this storage retry strategy,
  // /// used when a transaction fails on a first try
  // RetryStrategy? get retryStrategy => delegate.retryStrategy;

  /// returns a reference to a collection where name = [collectionName]
  CollectionReference<ID, T> collection<ID extends Object?, T extends Object?>(
    String collectionName, {
    options = const StorageOptions(),
  }) {
    return CollectionReference(
      delegate: delegate,
      collectionName: collectionName,
      options: options,
    );
  }

  destroy() {
    delegate.destroy();
  }

  Future serviceRequest(String serviceName, params) {
    return delegate.serviceRequest(serviceName, params);
  }
}
