import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/cascade_adapter/cascade_delegate.dart';

/// Adapter that implements caching mechanism.
///
/// When performing a read/write operation,
/// it starts with first adapter from adapters list
/// and goes through the list until one of the adapters succeeds,
/// or returns error of the last adapter if all adapters fail.
class CascadeAdapter<ID extends Object?> extends Adapter {
  CascadeAdapter(List<AdapterDelegateWithId> delegates)
      : super(CascadeDelegate(delegates));
}
