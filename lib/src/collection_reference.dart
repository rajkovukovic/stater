import 'package:stater/src/converters.dart';
import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/storage_options.dart';
import 'package:stater/src/utils/convert_document_snapshot.dart';

import 'query.dart';

class CollectionReference<ID extends Object?, T extends Object?>
    extends Query<ID, T> {
  CollectionReference({
    required super.delegate,
    required super.collectionName,
    super.options,
    super.converters,
  });

  Future<DocumentSnapshot<ID, T>?> add(
    T documentData, {
    ID? documentId,
    options = const StorageOptions(),
  }) =>
      converters == null
          ? delegate.addDocument<ID, T>(
              collectionName: collectionName,
              documentData: documentData,
              documentId: documentId,
              options: options,
            )
          : delegate
              .addDocument<ID, Map<String, dynamic>>(
                collectionName: collectionName,
                documentData: converters!.toHashMap(documentData),
                documentId: documentId,
                options: options,
              )
              .then((snapshot) =>
                  convertDocumentSnapshot(snapshot!, converters: converters));

  DocumentReference<ID, T> doc(ID documentId) {
    return DocumentReference<ID, T>(
      collectionName: collectionName,
      documentId: documentId,
      delegate: delegate,
      options: options,
    );
  }

  @override
  CollectionReference<RID, R> withConverters<RID, R>(
      Converters<RID, R> converters) {
    return CollectionReference<RID, R>(
      collectionName: collectionName,
      delegate: delegate,
      options: options,
      converters: converters,
    );
  }

  @override
  CollectionReference<RID, R> withConvertersFrom<RID, R>({
    required FromHashMap<RID, R> fromHashMap,
    required ToHashMap<R> toHashMap,
  }) {
    return CollectionReference<RID, R>(
      collectionName: collectionName,
      delegate: delegate,
      options: options,
      converters: Converters(fromHashMap, toHashMap),
    );
  }
}
