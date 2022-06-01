import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';

class Query<ID extends Object?, T extends Object?> {
  const Query({
    required this.delegate,
    required this.collectionName,
    this.compareOperations = const [],
    this.options = const StorageOptions(),
  });

  final StorageDelegate delegate;
  final String collectionName;
  final List<CompareOperation> compareOperations;
  final StorageOptions options;

  // Query<ID, T> _mapQuery(Query<Map<String, dynamic>> newOriginalQuery) {
  //   return Query<T>(
  //     newOriginalQuery,
  //     _fromHashMap,
  //     _toHashMap,
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

  Query<ID, T> whereOperation(CompareOperation compareOperation) {
    return Query(
        collectionName: collectionName,
        delegate: delegate,
        options: options,
        compareOperations: [...compareOperations, compareOperation]);
  }

  Query<ID, T> where(
    Object field,
    CompareOperator compareOperator,
    Object? valueToCompareTo,
  ) {
    return whereOperation(
        CompareOperation(field, compareOperator, valueToCompareTo));
  }

  // @override
  // bool operator ==(Object other) {
  //   return runtimeType == other.runtimeType &&
  //       other is Query<ID, T> &&
  //       other._fromHashMap == _fromHashMap &&
  //       other._toHashMap == _toHashMap &&
  //       other._originalQuery == _originalQuery;
  // }

  // @override
  // int get hashCode =>
  //     hashValues(runtimeType, _fromHashMap, _toHashMap, _originalQuery);
}

enum CompareOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
}

class CompareOperation {
  final Object field;
  final CompareOperator compareOperator;
  final Object? valueToCompareTo;

  const CompareOperation(
      this.field, this.compareOperator, this.valueToCompareTo);
}

typedef QueryMatcher<T extends Object?> = bool Function(T element, Query query);

typedef QueryCompareGenerator<ID extends Object?, T extends Object?> = int
        Function(DocumentSnapshot<ID, T> a, DocumentSnapshot<ID, T> b)?
    Function(Query query);
