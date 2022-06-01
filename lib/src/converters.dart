import 'document_snapshot.dart';

typedef FromStorage<ID, T> = T Function(DocumentSnapshot<ID, Map<String, dynamic>> snapshot);

typedef ToStorage<T> = Map<String, Object?> Function(T value);
