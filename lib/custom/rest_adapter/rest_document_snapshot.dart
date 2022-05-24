import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

class RestDocumentSnapshot<ID extends Object?, T extends Object?>
    implements DocumentSnapshot<ID, T> {
  RestDocumentSnapshot({
    T? data,
    required ID id,
    required DocumentReference<ID, T> reference,
  })  : _data = data,
        _id = id,
        _reference = reference;

  final T? _data;
  final ID _id;
  final DocumentReference<ID, T> _reference;

  @override
  T? data() {
    return _data;
  }

  @override
  bool get exists => _data != null;

  @override
  ID get id => _id;

  @override
  DocumentReference<ID, T> get reference => _reference;
}
