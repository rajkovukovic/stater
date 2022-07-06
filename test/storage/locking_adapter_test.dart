import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'make sure LockingAdapter does not allow a read operation '
      'to start until a write operation is completed', () async {
    final lockingAdapter = LockingAdapter(
      DelayedAdapter(
        InMemoryAdapter(generateSampleData()),
        readDelay: const Duration(milliseconds: 50),
        writeDelay: const Duration(milliseconds: 100),
      ),
    );

    final writeFuture = lockingAdapter.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        lockingAdapter.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '2');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });
}
