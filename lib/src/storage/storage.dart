import 'package:meta/meta.dart';
import 'package:stater/stater.dart';

class Storage<D extends StorageDelegate> {
  @protected
  final D delegate;

  Storage(this.delegate);

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

  Future request(String requestName, dynamic params) {
    throw 'Storage.request method should be overridden in classes'
        'that extends Storage class';
  }
}
