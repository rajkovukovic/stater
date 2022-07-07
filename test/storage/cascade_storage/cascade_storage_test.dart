// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'can create CascadeStorage using '
      'fake RestStorage(implemented as PuppetStorage + InMemoryStorage) and '
      'InMemoryStorage(implemented as DelayedStorage + InMemoryStorage)',
      () async {
    final cascadeStorage = generateCascadeAdapter(
        dataGenerator: generateSampleData,
        transactionGenerator: generateSampleTransactionsAsJson);

    final totalTransactions = generateSampleTransactionsAsJson().length;

    await Future.delayed(const Duration(milliseconds: 100));

    expect(cascadeStorage.transactionManager.transactionQueue.length,
        totalTransactions);
  });

  test(
      'can perform multiple operations '
      'on CascadeAdapter in proper order', () async {
    final cascadeAdapter = generateCascadeAdapter(
        dataGenerator: generateSampleData,
        transactionGenerator: generateSampleTransactionsAsJson);

    final fakeRestAdapter = cascadeAdapter.delegates.first as PuppetAdapter;
    final fakeLocalAdapter = cascadeAdapter.delegates.last;

    final restTodosRef =
        CollectionReference(delegate: fakeRestAdapter, collectionName: 'todos');

    final localTodosRef = CollectionReference(
        delegate: fakeLocalAdapter, collectionName: 'todos');

    final transactions = generateSampleTransactionsAsJson();
    final totalTransactions = transactions.length;

    // wait for storage init
    await Future.delayed(const Duration(milliseconds: 100));

    expect(
      cascadeAdapter.transactionManager.transactionQueue.length,
      totalTransactions,
    );

    for (var counter = 0; counter <= totalTransactions; counter++) {
      // counter of zero is used to verify initial state of adapters' state
      if (counter >= 1) {
        fakeRestAdapter.performNextWriteOperation();

        // wait for fakeRestAdapter to complete the operation,
        // for the operation to be delegated to the fakeLocalAdapter
        // and for fakeLocalAdapter to complete the operation
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(docsDataMapFromQuerySnapshot(await restTodosRef.get()),
          expectedSampleSnapshots[counter]['todos'],
          reason: 'REST todos do not match expectation after '
              '$counter transactions\n'
              '${counter > 0 ? 'last performed transaction '
                  '${transactions[counter - 1]}\n' : ''}');

      expect(docsDataMapFromQuerySnapshot(await localTodosRef.get()),
          expectedSampleSnapshots[counter]['todos'],
          reason: 'local todos do not match expectation after '
              '$counter transactions\n'
              '${counter > 0 ? 'last performed transaction '
                  '${transactions[counter - 1]}\n' : ''}');

      expect(
        cascadeAdapter.transactionManager.transactionQueue.length,
        totalTransactions - counter,
        reason: 'cascadeStorage.transactionManager.transactionQueue.length '
            'does not match',
      );
    }
  });

  test(
      'CascadeAdapter can perform getDocument and getQuery '
      'operations when read operations are after all '
      'the write operations', () async {
    final cascadeAdapter = generateCascadeAdapter(
        dataGenerator: generateSampleData,
        transactionGenerator: generateSampleTransactionsAsJson);

    final fakeRestAdapter = cascadeAdapter.delegates.first as PuppetAdapter;

    final transactions = generateSampleTransactionsAsJson();
    final totalTransactions = transactions.length;

    // wait for storage init
    await Future.delayed(const Duration(milliseconds: 100));

    // wait for all transactions to process
    for (var i = 0; i < totalTransactions; i++) {
      fakeRestAdapter.performNextWriteOperation();

      // wait for fakeRestAdapter to complete the operation,
      // for the operation to be delegated to the fakeLocalAdapter
      // and for fakeLocalAdapter to complete the operation
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final doc = await cascadeAdapter.getDocument(
        collectionName: 'todos', documentId: '3');

    expect(doc.data(), {'name': 'Todo 3', 'completed': false});

    final allDocs = await cascadeAdapter
        .getQuery(Query(collectionName: 'todos', delegate: cascadeAdapter));

    expect(docsDataMapFromQuerySnapshot(allDocs),
        expectedSampleSnapshots.last['todos']);
  });

  test(
      'CascadeAdapter can getDocument from secondary storage '
      'when primaryStorage returns an error', () async {
    final cascadeAdapter = generateCascadeAdapter(
      dataGenerator: generateSampleData,
      transactionGenerator: () => [],
      readOperationsSkipQueue: false,
    );

    final fakeRestAdapter = cascadeAdapter.delegates.first as PuppetAdapter;

    // wait for storage init
    await Future.delayed(const Duration(milliseconds: 1000));

    dynamic doc;
    dynamic docReadError;

    Future getDocumentRequest =
        cascadeAdapter.getDocument(collectionName: 'todos', documentId: '1');

    getDocumentRequest.then((value) => doc = value).catchError((error) {
      docReadError = error;
      return null;
    });

    fakeRestAdapter.performNextOperation(withError: 'Fake network error');

    await Future.delayed(const Duration(milliseconds: 50));

    expect(docReadError, null);

    expect(doc?.data(), {'name': 'Todo 1', 'completed': true});
  });
}

CascadeAdapter generateCascadeAdapter({
  required Map<String, Map<String, dynamic>> Function() dataGenerator,
  required List<Map<String, dynamic>> Function() transactionGenerator,
  bool readOperationsSkipQueue = true,
}) {
  final fakeLocalAdapter = createFakeLocalAdapter(dataGenerator);

  final fakeRestAdapter = createFakeRestAdapter(
    dataGenerator,
    readOperationsSkipQueue: readOperationsSkipQueue,
  );

  final transactionStorer = TransactionStorer(
    readTransactions: () {
      return Future.value(transactionGenerator());
    },
    readProcessedState: () => Future.value({}),
    writeTransactions: (_) => Future.value(null),
    writeProcessedState: (_) => Future.value(null),
  );

  return CascadeAdapter(
    primaryStorage: fakeRestAdapter,
    cachingStorages: [fakeLocalAdapter],
    transactionStoringDelegate: transactionStorer,
  );
}

StorageAdapter createFakeLocalAdapter(
        Map<String, Map<String, dynamic>> Function() dataGenerator) =>
    DelayedAdapter(
      InMemoryAdapter(dataGenerator(), id: 'inMemoryInsideLocal'),
      readDelay: const Duration(milliseconds: 25),
      writeDelay: const Duration(milliseconds: 50),
      id: 'local',
    );

PuppetAdapter createFakeRestAdapter(
  Map<String, Map<String, dynamic>> Function() dataGenerator, {
  bool readOperationsSkipQueue = true,
}) =>
    PuppetAdapter(
      InMemoryAdapter(dataGenerator(), id: 'inMemoryInsideRest'),
      id: 'rest',
      readOperationsSkipQueue: readOperationsSkipQueue,
    );
