import 'package:get_storage/get_storage.dart';
import 'package:stater/stater/adapters/adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';

import 'get_storage_collection_reference.dart';

class GetStorageAdapter<ID extends Object?, T extends Object?>
    implements Adapter<ID, T> {
  GetStorageAdapter(this.name) : storage = GetStorage(name) {
    // storage.erase();
  }

  final String name;
  GetStorage storage;

  @override
  CollectionReference<ID, T> collection(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) {
    return GetStorageCollectionReference(
      storage: storage,
      collectionPath: path,
      fromStorage: fromStorage,
      toStorage: toStorage,
    );
  }
}
