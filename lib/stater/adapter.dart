import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';

abstract class Adapter<ID extends Object?, T extends Object?> {
  AdapterDelegate<ID, T> get delegate;

  CollectionReference<ID, T> collection(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  });

  Adapter<ID, T> cloneWithDelegate(AdapterDelegate<ID, T> delegate);
}
