// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'can create CascadeStorage using '
      'InMemoryStorage(DelayedStorage + InMemoryStorage) and '
      'RestStorage(PuppetStorage + InMemoryStorage)', () async {
    final fakeLocalStorage = createFakeLocalStorage();
    final fakeRestStorage = createFakeRestStorage();
    final transactionStorer = TransactionStorer(
      readTransactions: () {
        return Future.value(generateSampleTransactionsAsJson());
      },
      readProcessedState: () => Future.value({}),
      writeTransactions: (_) => Future.value(null),
      writeProcessedState: (_) => Future.value(null),
    );

    final cascadeStorage = CascadeStorage(
      primaryStorage: fakeRestStorage,
      cachingStorages: [fakeLocalStorage],
      transactionStoringDelegate: transactionStorer,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    expect(cascadeStorage.transactionManager.transactionQueue.length, 4);
  });

  test('can perform 4 operations on cascadeStorage in proper order', () async {
    final fakeLocalStorage = createFakeLocalStorage();
    final fakeRestStorage = createFakeRestStorage();

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

    final cascadeStorage = CascadeStorage(
      primaryStorage: fakeRestStorage,
      cachingStorages: [fakeLocalStorage],
      transactionStoringDelegate: transactionStorer,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final totalTransactions = generateSampleTransactionsAsJson().length;

    expect(
      cascadeStorage.transactionManager.transactionQueue.length,
      totalTransactions,
    );

    for (var counter = totalTransactions; counter > 0; counter--) {
      print('\ncalling restStorage.performNextTransaction()');
      fakeRestStorage.performNextTransaction();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        cascadeStorage.transactionManager.transactionQueue.length,
        counter - 1,
        reason: 'cascadeStorage transactionQueue.length does not match',
      );
    }

    expect(
      cascadeStorage.transactionManager.transactionQueue.length,
      0,
    );
  });
}

CascadableStorage createFakeLocalStorage() => DelayedInMemoryStorage(
      generateSampleData(),
      readDelay: const Duration(milliseconds: 25),
      writeDelay: const Duration(milliseconds: 50),
      id: 'localStorage',
    );

PuppetStorage createFakeRestStorage() => PuppetStorage(
      internalStorage: InMemoryAdapter(generateSampleData()),
      id: 'restStorage',
    );
