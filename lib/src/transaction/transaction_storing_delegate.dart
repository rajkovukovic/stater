import 'dart:async';

import 'package:stater/stater.dart';

class TransactionStorer {
  final Future<List<Map<String, dynamic>>?> Function() readTransactions;
  final Future<Map<String, dynamic>?> Function() readProcessedState;
  final Future<dynamic> Function(List<Map<String, dynamic>>) writeTransactions;
  final Future<dynamic> Function(Map<String, dynamic>) writeProcessedState;

  TransactionStorer({
    required this.readTransactions,
    required this.readProcessedState,
    required this.writeTransactions,
    required this.writeProcessedState,
  });

  Future<dynamic> writeState({
    required List<Map<String, dynamic>> transactions,
    required Map<String, dynamic> processedState,
  }) {
    // print({'transactions': transactions, 'processedState': processedState});
    return Future.wait([
      writeTransactions(transactions),
      writeProcessedState(processedState),
    ]);
  }

  factory TransactionStorer.fromDocumentReferences({
    required DocumentReference transactionsDocRef,
    required DocumentReference processedStateDocRef,
  }) {
    return TransactionStorer(
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

  factory TransactionStorer.fromStorage(
    Storage storage, {
    String collectionName = 'uncommitted',
    String transactionsKey = 'transactions',
    String transactionsStateKey = 'transactionsState',
  }) {
    final collection =
        storage.collection('$internalCollectionPrefix$collectionName');

    return TransactionStorer.fromDocumentReferences(
      transactionsDocRef: collection.doc(transactionsKey),
      processedStateDocRef: collection.doc(transactionsStateKey),
    );
  }
}

const internalCollectionPrefix = '__internal__';

bool isInternalCollection(String collectionName) =>
    collectionName.startsWith(internalCollectionPrefix);
