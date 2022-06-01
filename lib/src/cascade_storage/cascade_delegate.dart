import 'package:stater/src/cascade_storage/cascade_transaction_manager.dart';
import 'package:stater/src/cascade_storage/exclusive_transaction.dart';
import 'package:stater/src/document_reference.dart';
import 'package:stater/src/document_snapshot.dart';
import 'package:stater/src/query.dart';
import 'package:stater/src/query_snapshot.dart';
import 'package:stater/src/storage_delegate.dart';
import 'package:stater/src/storage_options.dart';
import 'package:stater/src/transaction/operation.dart';
import 'package:stater/src/transaction/transaction_storing_delegate.dart';

bool ignoreCascadeDelegateAddDocumentWarning = false;
bool _warnedAboutStorageWithCacheAddDocument = false;

class CascadeDelegate extends StorageDelegate {
  late final List<StorageDelegateWithId> _delegates;
  late final CascadeTransactionManager<ExclusiveTransaction>
      _transactionManager;

  CascadeDelegate({
    required StorageDelegateWithId primaryDelegate,
    required List<StorageDelegateWithId>? cachingDelegates,
    required TransactionStoringDelegate transactionStoringDelegate,
  }) {
    _delegates = [
      primaryDelegate,
      if (cachingDelegates != null) ...cachingDelegates,
    ];
    _transactionManager = CascadeTransactionManager(
      delegates: _delegates,
      transactionStoringDelegate: transactionStoringDelegate,
    );
  }

  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>?>
      addDocument<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required T documentData,
    ID? documentId,
    options = const StorageOptions(),
  }) async {
    // we do not have an id generated on the UI, so it is not safe to make a
    // transaction out of this request, because document that is going to be
    // created won't have same id across all delegates which may cause
    // relation issues (like non existing foreign key)
    if (documentId == null) {
      if (!ignoreCascadeDelegateAddDocumentWarning &&
          !_warnedAboutStorageWithCacheAddDocument) {
        // ignore: avoid_print
        print('Calling collection.add method is not recommended when using '
            'CascadeStorage because this transactions will be discarded '
            'if it fails on the first try on the primary Storage.\n'
            'You may want to use collection.doc(generateNewUniqueId()).set '
            'method instead.\n'
            'To disable this message set variable '
            '"ignoreCascadeDelegateAddDocumentWarning" to true');
        _warnedAboutStorageWithCacheAddDocument = true;
      }

      return _delegates.first
          .addDocument<ID, T>(
        collectionName: collectionName,
        documentData: documentData,
        documentId: documentId,
        options: options,
      )
          .then((snapshot) {
        _delegates.sublist(1).forEach((delegate) {
          delegate.setDocument(
            collectionName: collectionName,
            documentId: snapshot!.id,
            documentData: documentData,
            options: options,
          );
        });
        return snapshot;
      });
    }
    // we have id generated on the UI, so it is safe to make
    // a transaction out of this request
    else if (options is StorageOptionsWithConverter) {
      _transactionManager.addTransaction(
        ExclusiveTransaction(operations: [
          OperationCreate(
            collectionName: collectionName,
            documentId: documentId.toString(),
            data: options.toHashMap(documentData),
          )
        ]),
      );
      return null;
    } else {
      throw 'CascadeDelegate.addDocument must be called with options of type '
          'StorageOptionsWithConverter';
    }
  }

  /// deletes the document
  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    _transactionManager.addTransaction(
      ExclusiveTransaction(operations: [
        OperationDelete(
            collectionName: collectionName, documentId: documentId.toString())
      ]),
    );
  }

  /// Reads the document
  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) {
    Future<DocumentSnapshot<ID, T>> delegateFuture(int delegateIndex) {
      return _delegates[delegateIndex]
          .getDocument<ID, T>(
              collectionName: collectionName, documentId: documentId)
          .catchError((error) {
        if (delegateIndex + 1 < _delegates.length) {
          return delegateFuture(delegateIndex + 1);
        }
      }).then(_postFetchDocument(
        collectionName: collectionName,
        sourceDelegateIndex: delegateIndex,
        options: options,
      ));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Reads the documents
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
        collectionName: query.collectionName,
        sourceDelegateIndex: delegateIndex,
        query: query,
      ));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Notifies of document updates at path defined by
  /// collectionName and documentId
  // @override
  // Stream<DocumentSnapshot<ID, T>>
  //     documentSnapshots<ID extends Object?, T extends dynamic>(
  //         String collectionName, ID documentId) {
  //   return MergeStream(
  //     _delegates.mapIndexed((delegateIndex, delegate) => delegate
  //         .documentSnapshots<ID, T>(collectionName, documentId)
  //         .map(_postFetchDocument(
  //           collectionName: collectionName,
  //           sourceDelegateIndex: delegateIndex,
  //         ))
  //         .handleError((_) => true)),
  //   ).shareReplay(maxSize: 1);
  // }

  /// Notifies of document updates matching the query
  // @override
  // Stream<QuerySnapshot<ID, T>>
  //     querySnapshots<ID extends Object?, T extends dynamic>(
  //         Query<ID, T> query) {
  //   return MergeStream(
  //       _delegates.mapIndexed((delegateIndex, delegate) => delegate
  //           .querySnapshots<ID, T>(query)
  //           .map(_postFetchQuery(
  //             collectionName: query.collectionName,
  //             sourceDelegateIndex: delegateIndex,
  //             query: query,
  //           ))
  //           .handleError((_) => true))).shareReplay(maxSize: 1);
  // }

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  @override
  Future<void> setDocument<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    if (options is StorageOptionsWithConverter) {
      _transactionManager.addTransaction(
        ExclusiveTransaction(operations: [
          OperationSet(
              collectionName: collectionName,
              documentId: documentId.toString(),
              data: options.toHashMap(documentData))
        ]),
      );
    } else {
      throw 'CascadeDelegate.setDocument must be called with options of type '
          'StorageOptionsWithConverter';
    }
  }

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    Map<String, dynamic>? documentData,
    options = const StorageOptions(),
  }) async {
    if (documentData != null) {
      _transactionManager.addTransaction(ExclusiveTransaction(operations: [
        OperationUpdate(
          collectionName: collectionName,
          documentId: documentId.toString(),
          data: documentData,
        )
      ]));
    }
  }

  /// writes this DocumentSnapshot.document to all the delegates
  /// and returns DocumentSnapshot cloned with delegate = "this"
  DocumentSnapshot<ID, T> Function(DocumentSnapshot<ID, T>)
      _postFetchDocument<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required int sourceDelegateIndex,
    options = const StorageOptions(),
  }) =>
          (documentSnapshot) {
            if (sourceDelegateIndex < _delegates.length - 1) {
              _transactionManager.insertTransaction(
                0,
                ExclusiveTransaction(
                  excludeDelegateWithIds: _delegates
                      .sublist(0, sourceDelegateIndex + 1)
                      .map((delegate) => delegate.id)
                      .toSet(),
                  operations: [
                    OperationSet(
                        collectionName: collectionName,
                        documentId: documentSnapshot.id.toString(),
                        data: documentSnapshot.data as dynamic)
                  ],
                ),
              );
            }

            return _applyTransactionsAndReplaceDelegateOfDocumentSnapshot(
              collectionName: collectionName,
              documentSnapshot: documentSnapshot,
              sourceDelegate: _delegates[sourceDelegateIndex],
            );
          };

  /// writes this QuerySnapshot.document to all delegates of lower priority
  /// and returns QuerySnapshot cloned with delegate = "this"
  QuerySnapshot<ID, T> Function(QuerySnapshot<ID, T>)
      _postFetchQuery<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required int sourceDelegateIndex,
    required Query<ID, T> query,
  }) =>
          (querySnapshot) {
            if (sourceDelegateIndex < _delegates.length - 1) {
              _transactionManager.insertTransaction(
                0,
                ExclusiveTransaction(
                  excludeDelegateWithIds: _delegates
                      .sublist(0, sourceDelegateIndex + 1)
                      .map((delegate) => delegate.id)
                      .toSet(),
                  operations: querySnapshot.docs
                      .map((documentSnapshot) => OperationSet(
                          collectionName: collectionName,
                          documentId: documentSnapshot.id.toString(),
                          data:
                              documentSnapshot.data() as Map<String, dynamic>))
                      .toList(),
                ),
              );
            }

            return _applyTransactionsAndReplaceDelegateOfQuerySnapshot(
              collectionName: collectionName,
              querySnapshot: querySnapshot,
              query: query,
              sourceDelegate: _delegates[sourceDelegateIndex],
            );
          };

  Iterable<ExclusiveTransaction> uncommittedTransactionsForDelegate(
      StorageDelegateWithId delegate) {
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
    required String collectionName,
    required DocumentSnapshot<ID, T> documentSnapshot,
    required StorageDelegateWithId sourceDelegate,
  }) {
    final uncommittedTransactions =
        uncommittedTransactionsForDelegate(sourceDelegate);

    final transformed = _transactionManager.applyTransactionsToEntity(
      collectionName: collectionName,
      documentId: documentSnapshot.id,
      data: documentSnapshot.data() as Map<String, dynamic>?,
      useThisTransactions: uncommittedTransactions,
    );

    return DocumentSnapshot<ID, T>(
      documentSnapshot.id,
      transformed,
      DocumentReference(
        collectionName: collectionName,
        documentId: documentSnapshot.id,
        delegate: this,
      ),
    );
  }

  /// clones QuerySnapshot and replaces it's delegate with "this"
  /// and applies all uncommitted transactions to every DocumentSnapshot.data
  QuerySnapshot<ID, T> _applyTransactionsAndReplaceDelegateOfQuerySnapshot<
      ID extends Object?, T extends dynamic>({
    required String collectionName,
    required QuerySnapshot<ID, dynamic> querySnapshot,
    required Query<ID, T> query,
    required StorageDelegateWithId sourceDelegate,
  }) {
    final uncommittedTransactions =
        uncommittedTransactionsForDelegate(sourceDelegate);

    final uncommittedCreatedDocuments = uncommittedTransactions
        .fold<Map<String, Map<String, dynamic>>>({}, (acc, transaction) {
      for (var operation in transaction.operations) {
        if (operation is OperationCreate) {
          if (operation.documentId == null) {
            throw 'having transaction with OperationCreate without '
                'a documentId may be a mistake?';
          }
          acc[operation.documentId!] = operation.data;
        }
      }
      return acc;
    });

    final uncommittedCreatedDocumentsRefs = uncommittedCreatedDocuments.entries
        .map((entry) => DocumentSnapshot<ID, T>(
              entry.key as ID,
              _transactionManager.applyTransactionsToEntity(
                collectionName: collectionName,
                documentId: entry.key,
                data: entry.value,
                useThisTransactions: uncommittedTransactions,
              ),
              DocumentReference(
                collectionName: collectionName,
                documentId: entry.key as ID,
                delegate: this,
              ),
            ))
        .where((documentSnapshot) =>
            documentSnapshot.exists &&
            sourceDelegate.doesMatchQuery(documentSnapshot.data(), query));

    final fromQuery = querySnapshot.docs
        .map((documentSnapshot) => DocumentSnapshot<ID, T>(
              documentSnapshot.id,
              _transactionManager.applyTransactionsToEntity(
                collectionName: collectionName,
                documentId: documentSnapshot.id,
                data: documentSnapshot.data(),
                useThisTransactions: uncommittedTransactions,
              ),
              DocumentReference(
                collectionName: collectionName,
                documentId: documentSnapshot.id,
                delegate: this,
              ),
            ))
        .where((documentSnapshot) =>
            documentSnapshot.exists &&
            sourceDelegate.doesMatchQuery(documentSnapshot.data(), query));

    final matched = [
      ...fromQuery,
      ...uncommittedCreatedDocumentsRefs,
    ];

    if (sourceDelegate.generateCompareFromQuery != null) {
      final compare = sourceDelegate.generateCompareFromQuery!(query);
      matched.sort(compare);
    }

    return QuerySnapshot<ID, T>(matched);
  }
}
