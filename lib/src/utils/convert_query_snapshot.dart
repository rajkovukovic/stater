import 'package:stater/stater.dart';

import 'convert_document_snapshot.dart';

QuerySnapshot<ID, Converted> convertQuerySnapshot<ID, T, Converted>(
  QuerySnapshot<ID, Map<String, dynamic>> querySnapshot, {
  required Converters<ID, Converted>? converters,
}) {
  return converters == null
      ? querySnapshot as QuerySnapshot<ID, Converted>
      : QuerySnapshot<ID, Converted>(querySnapshot.docs
          .map((doc) => convertDocumentSnapshot(doc, converters: converters))
          .toList());
}
