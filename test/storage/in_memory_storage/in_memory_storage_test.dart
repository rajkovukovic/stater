import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../../test_helpers.dart';

void main() {
  test('make sure InMemoryStorage can read an existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    final todo = await todosCollection.doc('1').get();

    expect(todo.id, '1');

    expect(todo.exists, true);

    expect(todo.data()?['name'], 'Todo 1');
  });

  test('make sure InMemoryStorage can create a document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    final todo = await todosCollection.add({'name': 'Todo 2'}, documentId: '2');

    expect(todo.id, '2');

    expect(todo.exists, true);

    expect(todo.data()?['name'], 'Todo 2');
  });

  test('make sure InMemoryStorage can read just created document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    await todosCollection.add({'name': 'Todo 2'}, documentId: '2');

    final todo = await todosCollection.doc('2').get();

    expect(todo.id, '2');

    expect(todo.exists, true);

    expect(todo.data()?['name'], 'Todo 2');
  });

  test('make sure InMemoryStorage can get a query', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    final todos = await todosCollection.get();

    expect(todos.size, 1);

    expect(todos.docs.first.exists, true);

    expect(todos.docs.first.id, '1');

    expect(todos.docs.first.data()?['name'], 'Todo 1');
  });

  test('make sure InMemoryStorage can delete a document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    await todosCollection.doc('1').delete();

    final todos = await todosCollection.get();

    expect(todos.size, 0);
  });

  test('make sure InMemoryStorage can update a document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    await todosCollection.doc('1').update({'completed': true});

    final todo = await todosCollection.doc('1').get();

    expect(todo.id, '1');

    expect(todo.exists, true);

    expect(todo.data()?['name'], 'Todo 1');

    expect(todo.data()?['completed'], true);
  });

  test('make sure InMemoryStorage can update a document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final todosCollection =
        inMemoryStorage.collection<String, Map<String, dynamic>>('todos');

    await todosCollection.doc('1').update({'completed': true});

    final todo = await todosCollection.doc('1').get();

    expect(todo.id, '1');

    expect(todo.exists, true);

    expect(todo.data()?['name'], 'Todo 1');

    expect(todo.data()?['completed'], true);
  });
}
