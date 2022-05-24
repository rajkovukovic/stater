import 'package:meta/meta.dart';
import 'package:stater/stater/adapter_delegate.dart';

import 'document_snapshot.dart';

@immutable
class DocumentReference<ID extends Object?, T extends Object?> {
  const DocumentReference(this._delegate, this.collectionPath, this.id);

  final AdapterDelegate _delegate;

  final String collectionPath;

  /// This document's given ID within the collection.
  final ID id;

  /// Deletes the current document from the collection.
  Future<void> delete() => _delegate.deleteDocument(collectionPath, id);

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot<ID, T>> get() =>
      _delegate.getDocument(collectionPath, id);

  /// Notifies of document updates at this location.
  ///
  /// An initial event is immediately sent, and further events will be
  /// sent whenever the document is modified.
  Stream<DocumentSnapshot<ID, T>> snapshots() =>
      _delegate.documentSnapshots(collectionPath, id);

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> set(T data) => _delegate.set(collectionPath, id, data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(Map<String, Object?> data) =>
      _delegate.update(collectionPath, id, data);
}
