import 'dart:async';

import 'package:stater/stater/storage_delegate.dart';
import 'package:stater/stater/document_reference.dart';
import 'package:stater/stater/storage.dart';

class TransactionStoringDelegate {
  final Future<List<Map<String, dynamic>>?> Function() readTransactions;
  final Future<Map<String, dynamic>?> Function() readProcessedState;
  final Future<dynamic> Function(List<Map<String, dynamic>>) writeTransactions;
  final Future<dynamic> Function(Map<String, dynamic>) writeProcessedState;

  TransactionStoringDelegate({
    required this.readTransactions,
    required this.readProcessedState,
    required this.writeTransactions,
    required this.writeProcessedState,
  });

  Future<dynamic> writeState({
    required List<Map<String, dynamic>> transactions,
    required Map<String, dynamic> processedState,
  }) {
    print({'transactions': transactions, 'processedState': processedState});
    return Future.wait([
      writeTransactions(transactions),
      writeProcessedState(processedState),
    ]);
  }

  factory TransactionStoringDelegate.fromDocumentReferences({
    required DocumentReference transactionsDocRef,
    required DocumentReference processedStateDocRef,
  }) {
    return TransactionStoringDelegate(
      readTransactions: () => transactionsDocRef.get().then((snapshot) =>
          (snapshot.data() as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()),
      readProcessedState: () => processedStateDocRef
          .get()
          .then((snapshot) => snapshot.data() as Map<String, dynamic>?),
      writeTransactions: (transactions) => transactionsDocRef.set(transactions),
      writeProcessedState: (processedState) =>
          processedStateDocRef.set(processedState),
    );
  }

  factory TransactionStoringDelegate.fromDelegate({
    required StorageDelegate delegate,
    required String collectionName,
    required String transactionsKey,
    required String transactionsStateKey,
  }) {
    final storage = Storage(delegate);
    final collection = storage.collection(collectionName);

    return TransactionStoringDelegate.fromDocumentReferences(
      transactionsDocRef: collection.doc(transactionsKey),
      processedStateDocRef: collection.doc(transactionsStateKey),
    );
  }
}
