import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../test_helpers/generate_sample_data.dart';
import '../test_helpers/slower_write_than_read_delegate.dart';

void main() {
  test(
      'make sure SlowerWriteThanReadDelegate does take more time'
      ' to perform a write than a read operation', () async {
    final slowWrite = SlowerWriteThanReadDelegate(generateSampleData());

    final writeFuture = slowWrite.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        slowWrite.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '1');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });

  test(
      'make sure SlowerWriteThanReadDelegate does not allow a read operation '
      'to start until a write operation is completed', () async {
    final slowWrite = SlowerWriteThanReadDelegate(generateSampleData());

    final lockingDelegate = LockingStorageDelegate(slowWrite);

    final writeFuture = lockingDelegate.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        lockingDelegate.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse?.id, '2');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0]?.id, '2');

    expect(bothResponses[1]?.id, '1');
  });
}
