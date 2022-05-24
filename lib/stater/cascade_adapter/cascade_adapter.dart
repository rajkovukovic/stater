import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/cascade_adapter/cascade_delegate.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';

/// Adapter that implements caching mechanism.
///
/// When performing a read/write operation,
/// it starts with first adapter from adapters list
/// and goes through the list until one of the adapters succeeds,
/// or returns error of the last adapter if all adapters fail.
class CascadeAdapter<ID extends Object?, T extends Object?>
    extends Adapter<ID, T> {
  late final List<Adapter<ID, T>> _adapters;
  late final CascadeDelegate<ID, T> _delegate;

  CascadeAdapter(this._adapters) {
    _delegate =
        CascadeDelegate(_adapters.map((adapter) => adapter.delegate).toList());
  }

  @override
  CollectionReference<ID, T> collection(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) {
    return CollectionReference(
        delegate: _delegate,
        collectionPath: path,
        fromStorage: fromStorage,
        toStorage: toStorage);
  }

  @override
  Adapter<ID, T> cloneWithDelegate(AdapterDelegate<ID, T> delegate) {
    throw UnimplementedError(
        'CascadeAdapter.cloneWithDelegate does not make sense to be implemented');
  }

  @override
  AdapterDelegate<ID, T> get delegate => _delegate;
}
