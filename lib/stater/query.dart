import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/converters.dart';
import 'package:stater/stater/query_snapshot.dart';

class Query<ID extends Object?, T extends Object?> {
  Query({
    required this.delegate,
    required this.parameters,
    required this.fromStorage,
    required this.toStorage,
  });

  final AdapterDelegate<ID, T> delegate;
  final Map<String, dynamic> parameters;
  final FromStorage<ID, T> fromStorage;
  final ToStorage<T> toStorage;

  // Query<ID, T> _mapQuery(Query<Map<String, dynamic>> newOriginalQuery) {
  //   return Query<T>(
  //     newOriginalQuery,
  //     _fromStorage,
  //     _toStorage,
  //   );
  // }

  Future<QuerySnapshot<ID, T>> get() => delegate.getQuery(this);

  Stream<QuerySnapshot<ID, T>> snapshots() => delegate.querySnapshots(this);

  // @override
  // Query<T> endAt(List<Object?> values) {
  //   return _mapQuery(_originalQuery.endAt(values));
  // }

  // @override
  // Query<T> endAtDocument(DocumentSnapshot documentSnapshot) {
  //   return _mapQuery(_originalQuery.endAtDocument(documentSnapshot));
  // }

  // @override
  // Query<T> endBefore(List<Object?> values) {
  //   return _mapQuery(_originalQuery.endBefore(values));
  // }

  // @override
  // Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) {
  //   return _mapQuery(_originalQuery.endBeforeDocument(documentSnapshot));
  // }

  // @override
  // Query<T> limit(int limit) {
  //   return _mapQuery(_originalQuery.limit(limit));
  // }

  // @override
  // Query<T> limitToLast(int limit) {
  //   return _mapQuery(_originalQuery.limitToLast(limit));
  // }

  // @override
  // Query<T> orderBy(Object field, {bool descending = false}) {
  //   return _mapQuery(_originalQuery.orderBy(field, descending: descending));
  // }

  // @override
  // Query<T> startAfter(List<Object?> values) {
  //   return _mapQuery(_originalQuery.startAfter(values));
  // }

  // @override
  // Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) {
  //   return _mapQuery(_originalQuery.startAfterDocument(documentSnapshot));
  // }

  // @override
  // Query<T> startAt(List<Object?> values) {
  //   return _mapQuery(_originalQuery.startAt(values));
  // }

  // @override
  // Query<T> startAtDocument(DocumentSnapshot documentSnapshot) {
  //   return _mapQuery(_originalQuery.startAtDocument(documentSnapshot));
  // }

  // @override
  // Query<T> where(
  //   Object field, {
  //   Object? isEqualTo,
  //   Object? isNotEqualTo,
  //   Object? isLessThan,
  //   Object? isLessThanOrEqualTo,
  //   Object? isGreaterThan,
  //   Object? isGreaterThanOrEqualTo,
  //   Object? arrayContains,
  //   List<Object?>? arrayContainsAny,
  //   List<Object?>? whereIn,
  //   List<Object?>? whereNotIn,
  //   bool? isNull,
  // }) {
  //   return _mapQuery(
  //     _originalQuery.where(
  //       field,
  //       isEqualTo: isEqualTo,
  //       isNotEqualTo: isNotEqualTo,
  //       isLessThan: isLessThan,
  //       isLessThanOrEqualTo: isLessThanOrEqualTo,
  //       isGreaterThan: isGreaterThan,
  //       isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
  //       arrayContains: arrayContains,
  //       arrayContainsAny: arrayContainsAny,
  //       whereIn: whereIn,
  //       whereNotIn: whereNotIn,
  //       isNull: isNull,
  //     ),
  //   );
  // }

  // @override
  // bool operator ==(Object other) {
  //   return runtimeType == other.runtimeType &&
  //       other is Query<ID, T> &&
  //       other._fromStorage == _fromStorage &&
  //       other._toStorage == _toStorage &&
  //       other._originalQuery == _originalQuery;
  // }

  // @override
  // int get hashCode =>
  //     hashValues(runtimeType, _fromStorage, _toStorage, _originalQuery);
}
