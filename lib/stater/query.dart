import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/converters.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query_snapshot.dart';

class Query<ID extends Object?, T extends Object?> {
  const Query({
    required this.delegate,
    required this.collectionPath,
    this.fromStorage,
    this.toStorage,
    this.compareOperations = const [],
  });

  final AdapterDelegate delegate;
  final String collectionPath;
  final FromStorage<ID, T>? fromStorage;
  final ToStorage<T>? toStorage;
  final List<CompareOperation> compareOperations;

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

  Query<ID, T> whereOperation(CompareOperation compareOperation) {
    return Query(
        collectionPath: collectionPath,
        delegate: delegate,
        fromStorage: fromStorage,
        toStorage: toStorage,
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
  //       other._fromStorage == _fromStorage &&
  //       other._toStorage == _toStorage &&
  //       other._originalQuery == _originalQuery;
  // }

  // @override
  // int get hashCode =>
  //     hashValues(runtimeType, _fromStorage, _toStorage, _originalQuery);
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
