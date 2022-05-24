import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';

class Adapter {
  final AdapterDelegate delegate;

  const Adapter(this.delegate);

  CollectionReference<ID, T> collection<ID extends Object?, T extends Object?>(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) {
    return CollectionReference(
        delegate: delegate,
        collectionPath: path,
        fromStorage: fromStorage,
        toStorage: toStorage);
  }
}
