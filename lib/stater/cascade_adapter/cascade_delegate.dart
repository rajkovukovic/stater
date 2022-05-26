import 'package:rxdart/rxdart.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/cascade_adapter/cascade_transaction_manager.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:stater/stater/transaction/operation.dart';
import 'package:stater/stater/transaction/transaction.dart';

bool ignoreCascadeDelegateAddDocumentWarning = false;
bool _warnedAboutAdapterWithCacheAddDocument = false;

class CascadeDelegate implements AdapterDelegate {
  final List<AdapterDelegateWithId> _delegates;
  late final CascadeTransactionManager _transactionManager;

  CascadeDelegate(this._delegates)
      : _transactionManager = CascadeTransactionManager(_delegates);

  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
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
    _transactionManager.addTransaction(Transaction([
      OperationDelete(
          collectionPath: collectionPath, documentId: documentId.toString())
    ]));
  }

  /// Reads the document
  @override
  Future<DocumentSnapshot<ID, T>>
      getDocument<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    Future<DocumentSnapshot<ID, T>> delegateFuture(int delegateIndex) {
      return _delegates[delegateIndex]
          .getDocument<ID, T>(collectionPath, documentId)
          .catchError((error) {
        if (delegateIndex + 1 < _delegates.length) {
          return delegateFuture(delegateIndex + 1);
        }
      }).then((response) {
        // TODO: use _transactionQueue instead of direct writting?
        _delegates.sublist(delegateIndex + 1).forEach((delegate) {
          delegate.setDocument(collectionPath, documentId, response.data());
        });
        return response;
      }).then(_copyDocumentSnapshotWithDelegate(collectionPath));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Reads the document
  @override
  Future<QuerySnapshot<ID, T>> getQuery<ID extends Object?, T extends Object?>(
      Query<ID, T> query) {
    Future<QuerySnapshot<ID, T>> delegateFuture(int delegateIndex) {
      return _delegates[delegateIndex]
          .getQuery<ID, T>(query)
          .catchError((error) {
        if (delegateIndex + 1 < _delegates.length) {
          return delegateFuture(delegateIndex + 1);
        }
      }).then((response) {
        // TODO: use _transactionQueue instead of direct writting?
        _delegates.sublist(delegateIndex + 1).forEach((delegate) {
          for (var doc in response.docs) {
            delegate.setDocument(query.collectionPath, doc.id, doc.data());
          }
        });
        return response;
      }).then(_copyQuerySnapshotWithDelegate(query.collectionPath));
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Notifies of document updates at path defined by
  /// collectionPath and documentId
  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    return MergeStream(
      _delegates.map((delegate) => delegate
          .documentSnapshots<ID, T>(collectionPath, documentId)
          .handleError((_) => true)),
    ).map(_copyDocumentSnapshotWithDelegate(collectionPath));
  }

  /// Notifies of document updates matching the query
  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(
          Query<ID, T> query) {
    return MergeStream(_delegates.map((delegate) =>
            delegate.querySnapshots<ID, T>(query).handleError((_) => true)))
        .map(_copyQuerySnapshotWithDelegate(query.collectionPath));
  }

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data) async {
    _transactionManager.addTransaction(Transaction([
      OperationSet(
          collectionPath: collectionPath,
          documentId: documentId.toString(),
          data: data as dynamic)
    ]));
  }

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    _transactionManager.addTransaction(Transaction([
      OperationUpdate(
          collectionPath: collectionPath,
          documentId: documentId.toString(),
          data: data as dynamic)
    ]));
  }

  /// clones DocumentSnapshot and replaces it's delegate with "this"
  DocumentSnapshot<ID, T> Function(DocumentSnapshot<ID, T>)
      _copyDocumentSnapshotWithDelegate<ID extends Object?, T extends Object?>(
              String collectionPath) =>
          (documentSnapshot) => DocumentSnapshot(
              documentSnapshot.id,
              documentSnapshot.data(),
              DocumentReference(collectionPath, documentSnapshot.id, this));

  /// clones QuerySnapshot and replaces it's delegate with "this"
  QuerySnapshot<ID, T> Function(QuerySnapshot<ID, T>)
      _copyQuerySnapshotWithDelegate<ID extends Object?, T extends Object?>(
              String collectionPath) =>
          (querySnapshot) => QuerySnapshot(querySnapshot.docs
              .map(_copyDocumentSnapshotWithDelegate(collectionPath))
              .toList());
}
