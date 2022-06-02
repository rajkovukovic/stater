import 'package:meta/meta.dart';

import 'document_reference.dart';

/// A [DocumentSnapshot] contains data read from a document in your [DB]
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
@sealed
class DocumentSnapshot<ID extends Object?, T extends Object?> {
  /// This document's given ID for this snapshot.
  final ID id;

  /// Returns the reference of this snapshot.
  final DocumentReference<ID, T> reference;

  final T? _data;

  const DocumentSnapshot(this.id, this._data, this.reference);

  DocumentSnapshot<CastedID, Casted> cast<CastedID, Casted>() {
    return DocumentSnapshot(
        id as CastedID, _data as Casted, reference.cast<CastedID, Casted>());
  }

  /// Metadata about this document concerning its source and if it has local
  /// modifications.
  // SnapshotMetadata get metadata;

  /// Returns `true` if the document exists.
  bool get exists => _data != null;

  /// Contains all the data of this document snapshot.
  T? data() => _data;

  /// {@template state_machine.DocumentSnapshot.get}
  /// Gets a nested field by [String] or [FieldPath] from this [DocumentSnapshot].
  ///
  /// Data can be accessed by providing a dot-notated path or [FieldPath]
  /// which recursively finds the specified data. If no data could be found
  /// at the specified path, a [StateError] will be thrown.
  /// {@endtemplate}
  // dynamic get(Object field);

  // /// {@macro state_machine.DocumentSnapshot.get}
  // dynamic operator [](Object field);
}
