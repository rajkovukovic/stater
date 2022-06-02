import 'document_snapshot.dart';

/// Contains the results of a query.
/// It can contain zero or more objects.
class QuerySnapshot<ID extends Object?, T extends Object?> {
  final List<DocumentSnapshot<ID, T>> _docs;

  const QuerySnapshot(this._docs);

  /// Gets a list of all the documents included in this snapshot.
  List<DocumentSnapshot<ID, T>> get docs => _docs;

  /// Returns the size (number of documents) of this snapshot.
  int get size => docs.length;

  QuerySnapshot<CastedID, Casted> cast<CastedID, Casted>() {
    return QuerySnapshot(
        _docs.map((doc) => doc.cast<CastedID, Casted>()).toList());
  }
}
