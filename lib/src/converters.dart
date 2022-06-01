import 'document_snapshot.dart';

typedef FromHashMap<ID, T> = T Function(
    DocumentSnapshot<ID, Map<String, dynamic>> snapshot);

typedef ToHashMap<T> = Map<String, dynamic> Function(T value);
