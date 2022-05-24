import 'converters.dart';
import 'document_reference.dart';
import 'query.dart';

abstract class CollectionReference<ID extends Object?, T extends Object?>
    extends Query<ID, T> {
  CollectionReference({
    required String collectionPath,
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) : super({'collectionPath': collectionPath}, fromStorage, toStorage);

  Future<DocumentReference<ID, T>> add(T data);
}
