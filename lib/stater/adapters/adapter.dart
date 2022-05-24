import 'package:stater/stater/collection_reference.dart';

import '../converters.dart';

abstract class Adapter<ID extends Object?, T extends Object?> {
  CollectionReference<ID, T> collection(
    String path, {
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  });
}
