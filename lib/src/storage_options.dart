import 'package:stater/stater.dart';

class StorageOptions {
  const StorageOptions();
}

class StorageOptionsWithConverter {
  final FromHashMap fromHashMap;
  final ToHashMap toHashMap;

  const StorageOptionsWithConverter({
    required this.fromHashMap,
    required this.toHashMap,
  });
}
