import 'package:stater/stater/adapters/adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/converters.dart';

import 'rest_collection_reference.dart';

class RestAdapter<ID extends Object?, T extends Object?>
    implements Adapter<ID, T> {
  RestAdapter(this.endpoint);

  final String endpoint;

  @override
  CollectionReference<ID, T> collection(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) {
    return RestCollectionReference(endpoint, path);
  }
}
