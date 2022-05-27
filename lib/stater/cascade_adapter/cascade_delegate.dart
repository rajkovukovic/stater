import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/cascade_adapter/cascade_transaction_manager.dart';
import 'package:stater/stater/cascade_adapter/exclusive_transaction.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:stater/stater/transaction/operation.dart';

bool ignoreCascadeDelegateAddDocumentWarning = false;
bool _warnedAboutAdapterWithCacheAddDocument = false;

class CascadeDelegate extends AdapterDelegate {
  final List<AdapterDelegateWithId> _delegates;
  late final CascadeTransactionManager<ExclusiveTransaction>
      _transactionManager;

  CascadeDelegate(this._delegates)
      : _transactionManager = CascadeTransactionManager(_delegates);

  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends dynamic>(
          String collectionPath, T doc) async {
    if (!ignoreCascadeDelegateAddDocumentWarning &&
        !_warnedAboutAdapterWithCacheAddDocument) {
      // ignore: avoid_print
      print('Calling collection.add method is not recommended when using '
          'CascadeAdapter because this transactions will be discarded '
          'if it fails on the first try on the primary Storage.\n'
          'You may want to use collection.doc(generateNewUniqueId()).set '
          'method instead.\n'
          'To disable this message set variable '
          '"ignoreCascadeDelegateAddDocumentWarning" to true');
      _warnedAboutAdapterWithCacheAddDocument = true;
    }
    return _delegates.first
        .addDocument<ID, T>(collectionPath, doc)
        .then((snapshot) {
      _delegates.sublist(1).forEach((delegate) {
        delegate.setDocument(collectionPath, snapshot.id, doc);
      });
      return snapshot;
    });
  }

  /// deletes the document
  @override
  Future<void> deleteDocument<ID extends Object?>(
      String collectionPath, ID documentId) async {
    _transactionManager.addTransaction(
      ExclusiveTransaction(operations: [
        OperationDelete(
            collectionPath: collectionPath, documentId: documentId.toString())
      ]),
    );
  }

  /// Reads the document
  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends dynamic>(
          String collectionPath, ID documentId) {
    Future<DocumentSnapshot<ID, T>> delegateFuture(int delegateIndex) {
      return _delegates[delegateIndex]
          .getDocument<ID, T>(collectionPath, documentId)
          .catchError((error) {
        if (delegateIndex + 1 < _delegates.length) {
          return delegateFuture(delegateIndex + 1);
        }
      }).then(_postFetchDocument(
        collectionPath: collectionPath,
        sourceDelegateIndex: delegateIndex,
      ));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Reads the document
  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends dynamic>(
      Query<ID, T> query) {
    // TODO: should we refactor to use ```for ... { await ... }``` ?
    Future<QuerySnapshot<ID, T>> delegateFuture(int delegateIndex) {
      return _delegates[delegateIndex]
          .getQuery<ID, T>(query)
          .catchError((error) {
        if (delegateIndex + 1 < _delegates.length) {
          return delegateFuture(delegateIndex + 1);
        }
      }).then(_postFetchQuery(
        collectionPath: query.collectionPath,
        sourceDelegateIndex: delegateIndex,
      ));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Notifies of document updates at path defined by
  /// collectionPath and documentId
  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends dynamic>(
          String collectionPath, ID documentId) {
    return MergeStream(
      _delegates.mapIndexed((delegateIndex, delegate) => delegate
          .documentSnapshots<ID, T>(collectionPath, documentId)
          .map(_postFetchDocument(
            collectionPath: collectionPath,
            sourceDelegateIndex: delegateIndex,
          ))
          .handleError((_) => true)),
    ).shareReplay(maxSize: 1);
  }

  /// Notifies of document updates matching the query
  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends dynamic>(
          Query<ID, T> query) {
    return MergeStream(
        _delegates.mapIndexed((delegateIndex, delegate) => delegate
            .querySnapshots<ID, T>(query)
            .map(_postFetchQuery(
              collectionPath: query.collectionPath,
              sourceDelegateIndex: delegateIndex,
            ))
            .handleError((_) => true))).shareReplay(maxSize: 1);
  }

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  @override
  Future<void> setDocument<ID extends Object?, T extends dynamic>(
      String collectionPath, ID documentId, T data) async {
    _transactionManager.addTransaction(
      ExclusiveTransaction(operations: [
        OperationSet(
            collectionPath: collectionPath,
            documentId: documentId.toString(),
            data: data as dynamic)
      ]),
    );
  }

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    _transactionManager.addTransaction(ExclusiveTransaction(operations: [
      OperationUpdate(
          collectionPath: collectionPath,
          documentId: documentId.toString(),
          data: data as dynamic)
    ]));
  }

  /// writes this DocumentSnapshot.document to all the delegates
  /// and returns DocumentSnapshot cloned with delegate = "this"
  DocumentSnapshot<ID, T> Function(DocumentSnapshot<ID, T>)
      _postFetchDocument<ID extends Object?, T extends dynamic>({
    required String collectionPath,
    required int sourceDelegateIndex,
  }) =>
          (documentSnapshot) {
            if (sourceDelegateIndex < _delegates.length - 1) {
              _transactionManager.addTransaction(
                ExclusiveTransaction(
                  excludeDelegateWithIds: _delegates
                      .sublist(0, sourceDelegateIndex + 1)
                      .map((delegate) => delegate.id)
                      .toSet(),
                  operations: [
                    OperationSet(
                        collectionPath: collectionPath,
                        documentId: documentSnapshot.id.toString(),
                        data: documentSnapshot.data as dynamic)
                  ],
                ),
              );
            }

            return _applyTransactionsAndReplaceDelegateOfDocumentSnapshot(
              collectionPath: collectionPath,
              documentSnapshot: documentSnapshot,
              sourceDelegate: _delegates[sourceDelegateIndex],
            );
          };

  /// writes this QuerySnapshot.document to all delegates of lower priority
  /// and returns QuerySnapshot cloned with delegate = "this"
  QuerySnapshot<ID, T> Function(QuerySnapshot<ID, T>)
      _postFetchQuery<ID extends Object?, T extends dynamic>({
    required String collectionPath,
    required int sourceDelegateIndex,
  }) =>
          (querySnapshot) {
            if (sourceDelegateIndex < _delegates.length - 1) {
              _transactionManager.addTransaction(
                ExclusiveTransaction(
                  excludeDelegateWithIds: _delegates
                      .sublist(0, sourceDelegateIndex + 1)
                      .map((delegate) => delegate.id)
                      .toSet(),
                  operations: querySnapshot.docs
                      .map((documentSnapshot) => OperationSet(
                          collectionPath: collectionPath,
                          documentId: documentSnapshot.id.toString(),
                          data:
                              documentSnapshot.data() as Map<String, dynamic>))
                      .toList(),
                ),
              );
            }

            return _applyTransactionsAndReplaceDelegateOfQuerySnapshot(
              collectionPath: collectionPath,
              querySnapshot: querySnapshot,
              sourceDelegate: _delegates[sourceDelegateIndex],
            );
          };

  Iterable<ExclusiveTransaction> uncommittedTransactionsForDelegate(
      AdapterDelegateWithId delegate) {
    final completedTransactionsIds =
        _transactionManager.completedTransactionsIds(delegate)!;

    return _transactionManager.getTransactionQueue().where((transaction) =>
        !transaction.excludeDelegateWithIds.contains(delegate.id) &&
        !completedTransactionsIds.contains(transaction.id));
  }

  /// clones DocumentSnapshot and replaces it's delegate with "this"
  /// and applies all uncommitted transactions to the DocumentSnapshot.data
  DocumentSnapshot<ID, T>
      _applyTransactionsAndReplaceDelegateOfDocumentSnapshot<ID extends Object?,
          T extends dynamic>({
    required String collectionPath,
    required DocumentSnapshot<ID, T> documentSnapshot,
    required AdapterDelegateWithId sourceDelegate,
  }) {
    final uncommittedTransactions =
        uncommittedTransactionsForDelegate(sourceDelegate);

    final transformed = _transactionManager.applyTransactionsToEntity(
      collectionPath: collectionPath,
      documentId: documentSnapshot.id,
      data: documentSnapshot.data() as Map<String, dynamic>?,
      useThisTransactions: uncommittedTransactions,
    );

    return DocumentSnapshot<ID, T>(
      documentSnapshot.id,
      transformed,
      DocumentReference(collectionPath, documentSnapshot.id, this),
    );
  }

  /// clones QuerySnapshot and replaces it's delegate with "this"
  /// and applies all uncommitted transactions to every DocumentSnapshot.data
  QuerySnapshot<ID, T> _applyTransactionsAndReplaceDelegateOfQuerySnapshot<
      ID extends Object?, T extends dynamic>({
    required String collectionPath,
    required QuerySnapshot<ID, dynamic> querySnapshot,
    required AdapterDelegateWithId sourceDelegate,
  }) {
    final uncommittedTransactions =
        uncommittedTransactionsForDelegate(sourceDelegate);

    return QuerySnapshot<ID, T>(querySnapshot.docs
        .map((documentSnapshot) => DocumentSnapshot<ID, T>(
              documentSnapshot.id,
              _transactionManager.applyTransactionsToEntity(
                collectionPath: collectionPath,
                documentId: documentSnapshot.id,
                data: documentSnapshot.data(),
                useThisTransactions: uncommittedTransactions,
              ),
              DocumentReference(collectionPath, documentSnapshot.id, this),
            ))
        .where((documentSnapshot) => documentSnapshot.exists)
        .toList());
  }
}
