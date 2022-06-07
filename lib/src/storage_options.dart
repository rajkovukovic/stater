import 'package:stater/stater.dart';

class StorageOptions {
  const StorageOptions();
}

class StorageOptionsWithConverters<ID, T> extends StorageOptions {
  final FromHashMap<ID, T> fromHashMap;
  final ToHashMap<T> toHashMap;

  const StorageOptionsWithConverters({
    required this.fromHashMap,
    required this.toHashMap,
  });

  factory StorageOptionsWithConverters.fromConverters(
      Converters<ID, T> converters) {
    return StorageOptionsWithConverters<ID, T>(
      fromHashMap: converters.fromHashMap,
      toHashMap: converters.toHashMap,
    );
  }
}
