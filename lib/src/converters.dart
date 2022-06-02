import 'document_snapshot.dart';

typedef FromHashMap<ID, T> = T Function(
    DocumentSnapshot<ID, Map<String, dynamic>> snapshot);

typedef ToHashMap<T> = Map<String, dynamic> Function(T value);

class Converters<ID, T> {
  final FromHashMap<ID, T> fromHashMap;
  final ToHashMap<T> toHashMap;

  const Converters(this.fromHashMap, this.toHashMap);
}
