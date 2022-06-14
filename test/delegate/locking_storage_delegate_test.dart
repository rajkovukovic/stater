import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../test_helpers.dart';

void main() {
  test(
      'make sure SlowWriteInMemoryDelegate does take more time'
      ' to perform a write than a read operation', () async {
    final slowWriteDelegate = SlowWriteInMemoryDelegate(generateSampleData());

    final writeFuture = slowWriteDelegate.addDocument(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo2'});

    final readFuture =
        slowWriteDelegate.getDocument(collectionName: 'todos', documentId: '1');

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '1');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });

  test(
      'make sure SlowWriteInMemoryDelegate does not allow a read operation '
      'to start until a write operation is completed', () async {
    final slowWrite = SlowWriteInMemoryDelegate(generateSampleData());

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

class SlowWriteInMemoryDelegate extends InMemoryDelegate {
  SlowWriteInMemoryDelegate(super.cache);

  @override
  Future<void> deleteDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(const Duration(microseconds: 10));

    return super.deleteDocument(
      collectionName: collectionName,
      documentId: documentId,
      options: options,
    );
  }

  @override
  Future<void> setDocument<ID extends Object?, T extends Object?>({
    required String collectionName,
    required ID documentId,
    required T documentData,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(const Duration(microseconds: 10));

    return super.setDocument(
        collectionName: collectionName,
        documentId: documentId,
        documentData: documentData,
        options: options);
  }

  @override
  Future<void> updateDocument<ID extends Object?>({
    required String collectionName,
    required ID documentId,
    required Map<String, dynamic> documentData,
    options = const StorageOptions(),
  }) async {
    await Future.delayed(const Duration(microseconds: 10));

    return super.updateDocument(
      collectionName: collectionName,
      documentId: documentId,
      documentData: documentData,
      options: options,
    );
  }
}
