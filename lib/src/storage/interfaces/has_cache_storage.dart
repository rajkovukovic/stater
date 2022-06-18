import 'package:fast_immutable_collections/fast_immutable_collections.dart';

abstract class HasCacheStorage {
  late Map<String, Map<String, dynamic>> data;

  late IMap<String, IMap<String, dynamic>> immutableData;
}
