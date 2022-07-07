import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stater/src/transaction/operation/get_document_operation.dart';
import 'package:stater/src/transaction/operation/get_query_operation.dart';
import 'package:stater/stater.dart';

bool ignoreCascadeStorageAddDocumentWarning = false;
bool _warnedAboutStorageWithCacheAddDocument = false;

class CascadeAdapter extends StorageAdapter {
  @protected
  late final List<StorageAdapter> delegates;

  @protected
  late final CascadeTransactionManager transactionManager;

  @protected
  late final JsonQueryMatcher queryMatcher;

  @protected
  late final ServiceProcessorFactory? serviceProcessorFactory;

  CascadeAdapter({
    required StorageAdapter primaryStorage,
    required List<StorageAdapter>? cachingStorages,
    required TransactionStorer transactionStoringDelegate,
    JsonQueryMatcher? queryMatcher,
    this.serviceProcessorFactory,
  }) {
    delegates = [
      primaryStorage,
      if (cachingStorages != null) ...cachingStorages,
    ];

    transactionManager = CascadeTransactionManager(
      delegates: delegates,
      transactionStoringDelegate: transactionStoringDelegate,
      serviceProcessorFactory: serviceProcessorFactory,
    );

    this.queryMatcher = queryMatcher ?? JsonQueryMatcher.empty();
  }

  @override
  void destroy() {
    transactionManager.destroy();
  }

  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>>
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
      if (!ignoreCascadeStorageAddDocumentWarning &&
          !_warnedAboutStorageWithCacheAddDocument) {
        // ignore: avoid_print
        print('Calling collection.add method is not recommended when using '
            'CascadeStorage because this transactions will be discarded '
            'if it fails on the first try on the primary Storage.\n'
            'You may want to use collection.doc(generateNewUniqueId()).set '
            'method instead.\n'
            'To disable this message set variable '
            '"ignoreCascadeStorageAddDocumentWarning" to true');
        _warnedAboutStorageWithCacheAddDocument = true;
      }

      return delegates.first
          .addDocument<ID, T>(
        collectionName: collectionName,
        documentData: documentData,
        documentId: documentId,
        options: options,
      )
          .then((snapshot) {
        delegates.sublist(1).forEach((delegate) {
          delegate.setDocument(
            collectionName: collectionName,
            documentId: snapshot.id,
            documentData: documentData,
            options: options,
          );
        });
        return snapshot;
      });
    }
    // we have id generated on the UI, so it is safe to make
    // a transaction out of this request
    else if (options is StorageOptionsWithConverters) {
      final completer = Completer();

      final data = options.toHashMap(documentData);

      transactionManager.addTransaction(
        ExclusiveTransaction(
          operations: [
            CreateOperation(
              collectionName: collectionName,
              documentId: documentId.toString(),
              data: data,
            )
          ],
        ),
      );

      return await completer.future;
    } else if (documentData is Map<String, dynamic>) {
      final completer = Completer();

      transactionManager.addTransaction(
        ExclusiveTransaction(
          operations: [
            CreateOperation(
              collectionName: collectionName,
              documentId: documentId.toString(),
              data: documentData,
            )
          ],
        ),
      );

      return await completer.future;
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
    final completer = Completer();

    transactionManager.addTransaction(
      ExclusiveTransaction(
        operations: [
          DeleteOperation(
            collectionName: collectionName,
            completer: completer,
            documentId: documentId.toString(),
          )
        ],
      ),
    );

    return completer.future;
  }

  /// Reads the document
  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends dynamic>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    final completer = Completer();

    transactionManager.addTransaction(
      ExclusiveTransaction(
        operations: [
          GetDocumentOperation(
            collectionName: collectionName,
            completer: completer,
            documentId: documentId.toString(),
          )
        ],
      ),
    );

    return await completer.future;
  }

  /// Reads the documents
  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends dynamic>(
    Query<ID, T> query, {
    Converters<ID, T>? converters,
    StorageOptions options = const StorageOptions(),
  }) async {
    final completer = Completer();

    transactionManager.addTransaction(
      ExclusiveTransaction(
        operations: [
          GetQueryOperation(
            collectionName: query.collectionName,
            completer: completer,
            query: query,
          )
        ],
      ),
    );

    return completer.future.then((data) {
      final convertedDocs = data.docs
          .map(
            (DocumentSnapshot doc) => DocumentSnapshot<ID, T>(
              doc.id as ID,
              converters?.fromHashMap(doc.data() as dynamic) ??
                  doc.data() as dynamic,
              DocumentReference<ID, T>(
                  collectionName: doc.reference.collectionName,
                  delegate: doc.reference.delegate,
                  documentId: doc.id as ID),
            ),
          )
          .cast<DocumentSnapshot<ID, T>>()
          .toList();

      return QuerySnapshot<ID, T>(convertedDocs);
    });
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
    final completer = Completer();

    transactionManager.addTransaction(
      ExclusiveTransaction(
        operations: [
          SetOperation(
              collectionName: collectionName,
              completer: completer,
              documentId: documentId.toString(),
              data: documentData as dynamic)
        ],
      ),
    );

    return completer.future;
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
    final completer = Completer();

    if (documentData != null) {
      transactionManager.addTransaction(
        ExclusiveTransaction(
          operations: [
            UpdateOperation(
              collectionName: collectionName,
              completer: completer,
              documentId: documentId.toString(),
              data: documentData,
            )
          ],
        ),
      );
    }

    return completer.future;
  }

  @override
  Future serviceRequest(String serviceName, dynamic params) async {
    final completer = Completer();

    transactionManager.addTransaction(
      ExclusiveTransaction(
        operations: [
          ServiceRequestOperation(
            completer: completer,
            serviceName: serviceName,
            params: params,
          )
        ],
      ),
    );

    return completer.future;
  }
}
