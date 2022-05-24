

import 'package:meta/meta.dart';

import 'document_reference.dart';

typedef FromRawDBEntry<ID, T> = T Function(
  DocumentSnapshot<ID, Map<String, dynamic>> snapshot,
  // SnapshotOptions? options,
);

typedef ToRawDBEntry<T> = Map<String, dynamic> Function(
  T value,
  // SetOptions? options,
);

/// A [DocumentSnapshot] contains data read from a document in your [DB]
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
@sealed
abstract class DocumentSnapshot<ID extends Object?, T extends Object?> {
  /// This document's given ID for this snapshot.
  ID get id;

  /// Returns the reference of this snapshot.
  DocumentReference<ID, T> get reference;

  /// Metadata about this document concerning its source and if it has local
  /// modifications.
  // SnapshotMetadata get metadata;

  /// Returns `true` if the document exists.
  bool get exists;

  /// Contains all the data of this document snapshot.
  T? data();

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

// class _JsonDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
//   _JsonDocumentSnapshot(this._firestore, this._delegate) {
//     DocumentSnapshotPlatform.verifyExtends(_delegate);
//   }

//   final FirebaseFirestore _firestore;
//   final DocumentSnapshotPlatform _delegate;

//   @override
//   String get id => _delegate.id;

//   @override
//   late final DocumentReference<Map<String, dynamic>> reference =
//       _firestore.doc(_delegate.reference.path);

//   @override
//   late final SnapshotMetadata metadata = SnapshotMetadata._(_delegate.metadata);

//   @override
//   bool get exists => _delegate.exists;

//   @override
//   Map<String, dynamic>? data() {
//     return {};
//   }

//   @override
//   dynamic get(Object field) {
//     return _CodecUtility.valueDecode(_delegate.get(field), _firestore);
//   }

//   @override
//   dynamic operator [](Object field) => get(field);
// }
