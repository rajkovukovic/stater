import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_snapshot.dart';

import 'converters.dart';
import 'query.dart';

class CollectionReference<ID extends Object?, T extends Object?>
    extends Query<ID, T> {
  CollectionReference({
    required AdapterDelegate delegate,
    required String collectionPath,
    required FromStorage<ID, T> fromStorage,
    required ToStorage<T> toStorage,
  }) : super(
            delegate: delegate,
            parameters: {'collectionPath': collectionPath},
            fromStorage: fromStorage,
            toStorage: toStorage);

  Future<DocumentSnapshot<ID, T>> add(T doc) =>
      delegate.addDocument(parameters['collectionPath'], doc);

  Future<DocumentSnapshot<ID, T>> doc(ID documentId) {
    return delegate.getDocument<ID, T>(
        parameters['collectionPath'], documentId);
  }
}
