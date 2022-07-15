import 'package:stater/stater.dart';

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
