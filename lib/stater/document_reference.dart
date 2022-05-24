import 'package:meta/meta.dart';

import 'document_snapshot.dart';

@sealed
@immutable
abstract class DocumentReference<ID extends Object?, T extends Object?> {
  /// This document's given ID within the collection.
  ID get id;

  /// Deletes the current document from the collection.
  Future<void> delete();


  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot<ID, T>> get();

  /// Notifies of document updates at this location.
  ///
  /// An initial event is immediately sent, and further events will be
  /// sent whenever the document is modified.
  Stream<DocumentSnapshot<ID, T>> snapshots();

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> set(T data);

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(Map<String, Object?> data);
}
