import 'package:flutter_test/flutter_test.dart';
import 'package:stater/src/storage/delayed_storage/delayed_storage.dart';
import 'package:stater/src/storage/in_memory_storage/in_memory_storage.dart';

import '../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'make sure Storage with locking strategy does not allow a read operation '
      'to start until a write operation is completed', () async {
    final lockingStorage = DelayedStorage(
      internalStorage: InMemoryStorage(generateSampleData()),
      readDelay: const Duration(milliseconds: 50),
      writeDelay: const Duration(milliseconds: 100),
    );

    final writeFuture = lockingStorage.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        lockingStorage.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '2');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });
}
