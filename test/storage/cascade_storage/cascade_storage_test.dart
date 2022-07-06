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
    final fakeLocalAdapter = createFakeLocalAdapter();
    final fakeRestAdapter = createFakeRestAdapter();
    final transactionStorer = TransactionStorer(
      readTransactions: () {
        return Future.value(generateSampleTransactionsAsJson());
      },
      readProcessedState: () => Future.value({}),
      writeTransactions: (_) => Future.value(null),
      writeProcessedState: (_) => Future.value(null),
    );

    final cascadeStorage = CascadeAdapter(
      primaryStorage: fakeRestAdapter,
      cachingStorages: [fakeLocalAdapter],
      transactionStoringDelegate: transactionStorer,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    expect(cascadeStorage.transactionManager.transactionQueue.length, 4);
  });

  test(
      'can perform multiple operations '
      'on cascadeStorage in proper order', () async {
    final fakeLocalAdapter = createFakeLocalAdapter();
    final fakeRestAdapter = createFakeRestAdapter();

    final List<List<Map<String, dynamic>>> storedTransactions = [];
    final List<Map<String, dynamic>> storedTransactionsState = [];

    final transactionStorer = TransactionStorer(
      readTransactions: () {
        return Future.value(generateSampleTransactionsAsJson());
      },
      readProcessedState: () => Future.value({}),
      writeTransactions: (data) async => storedTransactions.add(data),
      writeProcessedState: (data) async => storedTransactionsState.add(data),
    );

    final cascadeAdapter = CascadeAdapter(
      primaryStorage: fakeRestAdapter,
      cachingStorages: [fakeLocalAdapter],
      transactionStoringDelegate: transactionStorer,
    );

    final localTodosRef = CollectionReference(
      delegate: fakeLocalAdapter,
      collectionName: 'todos',
    );

    final restTodosRef = CollectionReference(
      delegate: fakeRestAdapter,
      collectionName: 'todos',
    );

    final transactions = generateSampleTransactionsAsJson();
    final totalTransactions = transactions.length;

    // wait for storage init
    await Future.delayed(const Duration(milliseconds: 100));

    expect(
      cascadeAdapter.transactionManager.transactionQueue.length,
      totalTransactions,
    );

    for (var counter = 0; counter <= totalTransactions; counter++) {
      if (counter >= 1) {
        fakeRestAdapter.performNextWriteOperation();

        // wait for fakeRestAdapter to complete the operation,
        // for the operation to be delegated to the fakeLocalAdapter
        // and for fakeLocalAdapter to complete the operation
        await Future.delayed(const Duration(milliseconds: 100));
      }

      expect(docsDataMapFromQuerySnapshot(await localTodosRef.get()),
          expectedSampleSnapshots[counter]['todos'],
          reason: 'local todos do not match expectation after '
              '$counter transactions\n'
              '${counter > 0 ? 'last performed transaction '
                  'id="${transactions[counter - 1]}"\n' : ''}');

      expect(docsDataMapFromQuerySnapshot(await restTodosRef.get()),
          expectedSampleSnapshots[counter]['todos'],
          reason: 'REST todos do not match expectation after '
              '$counter transactions\n'
              '${counter > 0 ? 'last performed transaction '
                  'id="${transactions[counter - 1]}"\n' : ''}');

      expect(
        cascadeAdapter.transactionManager.transactionQueue.length,
        totalTransactions - counter,
        reason: 'cascadeStorage.transactionManager.transactionQueue.length '
            'does not match',
      );
    }
  });
}

StorageAdapter createFakeLocalAdapter() => DelayedAdapter(
      InMemoryAdapter(generateSampleData(), id: 'inMemoryInsideLocal'),
      readDelay: const Duration(milliseconds: 25),
      writeDelay: const Duration(milliseconds: 50),
      id: 'local',
    );

PuppetAdapter createFakeRestAdapter() => PuppetAdapter(
      InMemoryAdapter(generateSampleData(), id: 'inMemoryInsideRest'),
      id: 'rest',
      readOperationsSkipQueue: true,
    );
