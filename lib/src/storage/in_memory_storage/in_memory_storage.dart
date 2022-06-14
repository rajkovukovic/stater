import 'package:stater/stater.dart';

/// in-RAM StorageDelegate used for super fast operations
class InMemoryStorage extends Storage {
  InMemoryStorage([Map<String, Map<String, dynamic>>? cache])
      : super(InMemoryDelegate(cache ?? {}));

  InMemoryStorage.fromDelegate(InMemoryDelegate delegate) : super(delegate);

  // static FutureOr<InMemoryStorage> fromClonedData(
  //   QuickStorageDelegate delegate,
  // ) async {
  //   final cloned = await InMemoryDelegate.fromClonedData(delegate);
  //   return InMemoryStorage.fromDelegate(cloned);
  // }
}
