import 'package:stater/stater.dart';

class StorageOptions {
  const StorageOptions();
}

class StorageOptionsWithConverter<ID, T> {
  final FromHashMap<ID, T> fromHashMap;
  final ToHashMap<T> toHashMap;

  const StorageOptionsWithConverter({
    required this.fromHashMap,
    required this.toHashMap,
  });
}
