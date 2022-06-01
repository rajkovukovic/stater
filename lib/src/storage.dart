import 'package:meta/meta.dart';
import 'package:stater/src/collection_reference.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';

class Storage {
  @protected
  final StorageDelegate delegate;

  Storage(this.delegate);

  CollectionReference<ID, T> collection<ID extends Object?, T extends Object?>(
    String path, {
    StorageOptions options = const StorageOptions(),
  }) {
    return CollectionReference(
      delegate: delegate,
      collectionName: path,
      options: options,
    );
  }
}
