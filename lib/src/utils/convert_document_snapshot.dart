import 'package:stater/stater.dart';

DocumentSnapshot<ID, Converted>
    convertDocumentSnapshot<ID, T extends Map<String, dynamic>, Converted>(
  DocumentSnapshot<ID, Map<String, dynamic>> documentSnapshot, {
  required Converters<ID, Converted>? converters,
}) {
  return converters == null
      ? documentSnapshot as DocumentSnapshot<ID, Converted>
      : DocumentSnapshot<ID, Converted>(
          documentSnapshot.id,
          converters.fromHashMap(documentSnapshot.cast<ID, T>()),
          DocumentReference(
              collectionName: documentSnapshot.reference.collectionName,
              documentId: documentSnapshot.id,
              delegate: documentSnapshot.reference.delegate,
              options: documentSnapshot.reference.options,
              converters: converters));
}
