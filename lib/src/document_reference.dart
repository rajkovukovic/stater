import 'package:meta/meta.dart';
import 'package:stater/src/utils/convert_document_snapshot.dart';
import 'package:stater/stater.dart';


@immutable
class DocumentReference<ID extends Object?, T extends Object?> {
  const DocumentReference({
    required this.collectionName,
    required ID documentId,
    required this.delegate,
    this.options = const StorageOptions(),
    this.converters,
  }) : id = documentId;

  final Storage delegate;

  final String collectionName;

  /// This document's given ID within the collection.
  final ID id;

  final StorageOptions options;

  final Converters<ID, T>? converters;

  DocumentReference<CastedID, Casted> cast<CastedID, Casted>() {
    return DocumentReference(
        collectionName: collectionName,
        documentId: id as CastedID,
        delegate: delegate,
        options: options);
  }

  /// Deletes the current document from the collection.
  Future<void> delete({
    options = const StorageOptions(),
  }) =>
      delegate.deleteDocument(
        collectionName: collectionName,
        documentId: id,
        options: options,
      );

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot<ID, T>> get({
    options = const StorageOptions(),
  }) =>
      delegate
          .getDocument<ID, Object?>(
            collectionName: collectionName,
            documentId: id,
          )
          .then((documentSnapshot) => converters == null
              ? documentSnapshot.cast<ID, T>()
              : convertDocumentSnapshot(
                  documentSnapshot.cast<ID, Map<String, dynamic>>(),
                  converters: converters,
                ));

  // /// Notifies of document updates at this location.
  // ///
  // /// An initial event is immediately sent, and further events will be
  // /// sent whenever the document is modified.
  // Stream<DocumentSnapshot<ID, T>> snapshots({
  //   options = const StorageOptions(),
  // }) =>
  //     delegate.documentSnapshots(
  //       collectionName: collectionName,
  //       documentId: id,
  //       options: options,
  //     );

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> set(T documentData) => delegate.setDocument(
        collectionName: collectionName,
        documentId: id,
        documentData: converters == null
            ? documentData
            : converters!.toHashMap(documentData),
        options: options,
      );

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(
    Map<String, dynamic> documentData, {
    options = const StorageOptions(),
  }) =>
      delegate.updateDocument(
        collectionName: collectionName,
        documentId: id,
        documentData: documentData,
        options: options,
      );
}
