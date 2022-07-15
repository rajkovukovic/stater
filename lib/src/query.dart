import 'package:stater/src/utils/convert_query_snapshot.dart';
import 'package:stater/stater.dart';

class Query<ID extends Object?, T extends Object?> {
  const Query(
      {required this.delegate,
      required this.collectionName,
      this.compareOperations = const [],
      this.options = const StorageOptions(),
      this.converters});

  final StorageAdapter delegate;
  final String collectionName;
  final List<CompareOperation> compareOperations;
  final StorageOptions options;
  final Converters<ID, T>? converters;

  // Query<ID, T> _mapQuery(Query<Map<String, dynamic>> newOriginalQuery) {
  //   return Query<T>(
  //     newOriginalQuery,
  //     _fromHashMap,
  //     _toHashMap,
  //   );
  // }

  /// invokes data fetching
  ///
  /// returns a Future that resolves to QuerySnapshot
  Future<QuerySnapshot<ID, T>> get() =>
      delegate.getQuery<ID, Object?>(this).then((QuerySnapshot querySnapshot) =>
          convertQuerySnapshot(querySnapshot.cast<ID, Map<String, dynamic>>(),
              converters: converters));

  // Stream<QuerySnapshot<ID, T>> snapshots({
  //   options = const StorageOptions(),
  // }) =>
  //     delegate.querySnapshots(query: this, options: options);

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

  Query<ID, T> copyWithCompareOperations(
    List<CompareOperation> compareOperations,
  ) {
    return Query(
        converters: converters,
        collectionName: collectionName,
        delegate: delegate,
        options: options,
        compareOperations: compareOperations);
  }

  Query<ID, T> whereOperation(CompareOperation compareOperation) {
    return Query(
        converters: converters,
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

  Query<RID, R> withConverters<RID, R>(Converters<RID, R> converters) {
    return Query<RID, R>(
      collectionName: collectionName,
      delegate: delegate,
      compareOperations: compareOperations,
      options: options,
      converters: converters,
    );
  }

  Query<RID, R> withConvertersFrom<RID, R>({
    required FromHashMap<RID, R> fromHashMap,
    required ToHashMap<R> toHashMap,
  }) {
    return Query<RID, R>(
      collectionName: collectionName,
      delegate: delegate,
      compareOperations: compareOperations,
      options: options,
      converters: Converters(fromHashMap, toHashMap),
    );
  }
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

// typedef QueryMatcher<T extends Object?> = bool Function(T element, Query query);

typedef QueryCompareGenerator<ID extends Object?, T extends Object?> = int
        Function(DocumentSnapshot<ID, T> a, DocumentSnapshot<ID, T> b)?
    Function(Query query);
