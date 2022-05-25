import 'package:rxdart/rxdart.dart';
import 'package:stater/stater/adapter_delegate.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/stater/query_snapshot.dart';
import 'package:stater/stater/transaction/document_change.dart';
import 'package:stater/stater/transaction/transaction.dart';

bool ignoreCascadeDelegateAddDocumentWarning = false;
bool _warnedAboutAdapterWithCacheAddDocument = false;

class CascadeDelegate implements AdapterDelegate {
  final List<AdapterDelegate> _delegates;
  final List<Transaction> _transactionQueue = [];
  final List<Function()> _listeners = [];

  CascadeDelegate(this._delegates);

  void _addTransaction(Transaction transaction) {
    _transactionQueue.add(transaction);
    _notifyListeners();
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener.call();
    }
  }

  /// creates a new document
  @override
  Future<DocumentSnapshot<ID, T>>
      addDocument<ID extends Object?, T extends Object?>(
          String collectionPath, T doc) async {
    if (!ignoreCascadeDelegateAddDocumentWarning &&
        !_warnedAboutAdapterWithCacheAddDocument) {
      // ignore: avoid_print
      print(
          'Calling collection.add method is not recommended when using CascadeAdapter '
          'because this transactions will stay in the transactions queue until the primary adapter commits it successfully. '
          'You may want to use collection.doc(generateNewUniqueId()).set method instead.\n'
          'To disable this message set variable "ignoreCascadeDelegateAddDocumentWarning" to true');
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
    _addTransaction(Transaction([
      DocumentChange(
          collectionPath: collectionPath,
          changeType: DocumentChangeType.delete,
          param: documentId)
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
      });
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
      });
    }

    // try with first delegate, use next one in case of error
    // until getting a successful response or no more delegates
    return delegateFuture(0);
  }

  /// Notifies of document updates at this location.
  @override
  Stream<DocumentSnapshot<ID, T>>
      documentSnapshots<ID extends Object?, T extends Object?>(
          String collectionPath, ID documentId) {
    return MergeStream(_delegates.map(
        (delegate) => delegate.documentSnapshots(collectionPath, documentId)));
  }

  /// Notifies of document updates at this location.
  @override
  Stream<QuerySnapshot<ID, T>>
      querySnapshots<ID extends Object?, T extends Object?>(
          Query<ID, T> query) {
    return MergeStream(_delegates.map((delegate) =>
        delegate.querySnapshots<ID, T>(query).handleError((_) => true)));
  }

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>(
      String collectionPath, ID documentId, T data) async {
    _addTransaction(Transaction([
      DocumentChange(
          collectionPath: collectionPath,
          changeType: DocumentChangeType.set,
          param: [documentId, data])
    ]));
  }

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  @override
  Future<void> updateDocument<ID extends Object?>(
      String collectionPath, ID documentId, Map<String, Object?> data) async {
    _addTransaction(Transaction([
      DocumentChange(
          collectionPath: collectionPath,
          changeType: DocumentChangeType.update,
          param: [documentId, data])
    ]));
  }
}
