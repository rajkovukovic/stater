import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/delayed_storage.dart';
import '../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'make sure Storage with locking strategy does not allow a read operation '
      'to start until a write operation is completed', () async {
    final lockingDelegate = DelayedStorage(
      cache: generateSampleData(),
      readDelay: const Duration(milliseconds: 50),
      writeDelay: const Duration(milliseconds: 100),
    );

    final writeFuture = lockingDelegate.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        lockingDelegate.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '2');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });
}
