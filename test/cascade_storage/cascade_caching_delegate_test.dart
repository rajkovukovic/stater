import 'package:flutter_test/flutter_test.dart';
import 'package:stater/src/cascade_storage/cascade_caching_delegate.dart';
import 'package:stater/stater.dart';

import '../test_helpers/generate_sample_data.dart';
import '../test_helpers/slower_write_than_read_delegate.dart';

void main() {
  test(
      'make sure initialTransactions are being performed before'
      ' transactions requested during the init process', () async {
    final dataFuture =
        Future.delayed(const Duration(milliseconds: 100), generateSampleData);

    final transactionsFuture = Future.delayed(
        const Duration(milliseconds: 100), generateSampleTransactions);

    final delegate = CascadeCachingDelegate(
      dataFuture: dataFuture,
      uncommittedTransactionsFuture: transactionsFuture,
      innerDelegateCreator: (data) => SlowerWriteThanReadDelegate(data),
    );

    final readTodo1Future =
        delegate.getDocument(collectionName: 'todos', documentId: '1');

    final todo1 = await readTodo1Future;

    expect(todo1.id, '1');

    expect(todo1.exists, true);

    expect((todo1.data() as Map<String, dynamic>)['name'], 'Todo 1.1');
  });

  test(
      'make sure transactions requested during the init process'
      ' are executed with write transactions locking the storage', () async {
    final dataFuture =
        Future.delayed(const Duration(milliseconds: 100), generateSampleData);

    final transactionsFuture = Future.delayed(
        const Duration(milliseconds: 100), generateSampleTransactions);

    final delegate = CascadeCachingDelegate(
      dataFuture: dataFuture,
      uncommittedTransactionsFuture: transactionsFuture,
      innerDelegateCreator: (data) => SlowerWriteThanReadDelegate(data),
    );

    final readTodo1Future =
        delegate.getDocument(collectionName: 'todos', documentId: '1');

    delegate.addDocument(
        collectionName: 'todos',
        documentId: '3',
        documentData: {'name': 'Todo 3'});

    final readAllTodosFuture =
        delegate.getQuery(Query(delegate: delegate, collectionName: 'todos'));

    final todo1 = await readTodo1Future;

    final allTodos = await readAllTodosFuture;

    expect(todo1.id, '1');

    expect(todo1.exists, true);

    expect((todo1.data() as Map<String, dynamic>)['name'], 'Todo 1.1');

    expect(allTodos.size, 3);
  });
}
