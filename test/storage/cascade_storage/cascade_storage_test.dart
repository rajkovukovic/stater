// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:stater/src/storage/cascade_storage/cascade_storage.dart';
import 'package:stater/stater.dart';

import '../../test_helpers/generate_sample_data.dart';
import '../../test_helpers/puppet_storage.dart';

void main() {
  test('can create CascadeStorage using inMemoryStorage and restStorage',
      () async {
    final fakeLocalStorage = createLocalStorage();
    final fakeRestStorage = createRestStorage();
    final transactionStorer = TransactionStorer(
      readTransactions: () => Future.value(generateSampleTransactionsAsJson()),
      readProcessedState: () => Future.value({}),
      writeTransactions: (_) => Future.value(null),
      writeProcessedState: (_) => Future.value(null),
    );

    final cascadeStorage = CascadeStorage(
      primaryDelegate: fakeRestStorage,
      cachingDelegates: [fakeLocalStorage],
      transactionStoringDelegate: transactionStorer,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    final totalTransactions = generateSampleTransactionsAsJson().length;

    expect(
      cascadeStorage.transactionManager.transactionQueue.length,
      totalTransactions,
    );

    for (var counter = totalTransactions; counter > 0; counter++) {
      fakeRestStorage.performNextTransaction();

      await Future.delayed(const Duration(milliseconds: 1000));

      expect(
        cascadeStorage.transactionManager.transactionQueue.length,
        counter - 1,
        reason: 'cascadeStorage transactionQueue.length does not match',
      );
    }

    expect(
      cascadeStorage.transactionManager.transactionQueue.length,
      totalTransactions,
    );
  });
}

InMemoryStorage createLocalStorage() =>
    InMemoryStorage(generateSampleData())..id = 'localStorage';

PuppetStorage createRestStorage() =>
    PuppetStorage(id: 'restStorage', cache: generateSampleData());
