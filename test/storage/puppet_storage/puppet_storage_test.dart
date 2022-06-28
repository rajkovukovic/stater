// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';
import 'package:stater/stater.dart';

import '../../test_helpers/generate_sample_data.dart';

void main() {
  test(
      'PuppetStorage does not perform a transaction if method '
      'performNextTransaction() is not called', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    DocumentSnapshot<String, Map<String, dynamic>>? todo;

    todosCollection.doc('1').get().then((response) => todo = response);

    await Future.delayed(const Duration(milliseconds: 100));

    expect(todo, null);

    expect(puppetStorage.hasPendingTransactions(), true);
  });

  test('PuppetStorage can read an existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    DocumentSnapshot<String, Map<String, dynamic>>? todo;

    todosCollection.doc('1').get().then((response) => todo = response);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(todo?.id, '1');

    expect(todo?.exists, true);

    expect(todo?.data()?['name'], 'Todo 1');

    expect(puppetStorage.hasPendingTransactions(), false);
  });

  test('PuppetStorage can delete an existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    bool isDeleted = false;

    todosCollection.doc('1').delete().then((_) => isDeleted = true);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(isDeleted, true);

    expect(puppetStorage.hasPendingTransactions(), false);

    /// verify document does not exist

    DocumentSnapshot<String, Map<String, dynamic>>? todo;

    todosCollection.doc('1').get().then((response) => todo = response);

    puppetStorage.performNextTransaction();

    expect(todo, null);
  });

  test('PuppetStorage can update an existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    bool isUpdated = false;

    todosCollection
        .doc('1')
        .update({'name': 'updated'}).then((_) => isUpdated = true);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(isUpdated, true);

    expect(puppetStorage.hasPendingTransactions(), false);

    /// verify document has been updated

    DocumentSnapshot<String, Map<String, dynamic>>? todo;

    todosCollection.doc('1').get().then((response) => todo = response);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(todo?.id, '1');

    expect(todo?.exists, true);

    expect(todo?.data()?['name'], 'updated');
  });

  test('PuppetStorage can read all existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    QuerySnapshot<String, Map<String, dynamic>>? todos;

    todosCollection.get().then((response) {
      todos = response;
    });

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(todos?.size, 1);

    expect(puppetStorage.hasPendingTransactions(), false);
  });

  test('PuppetStorage can update an existing document', () async {
    final inMemoryStorage = InMemoryStorage(generateSampleData());

    final puppetStorage = PuppetStorage(internalStorage: inMemoryStorage);

    final todosCollection =
        puppetStorage.collection<String, Map<String, dynamic>>('todos');

    bool isUpdated = false;

    todosCollection.doc('1').update({'name': 'set', 'completed': true}).then(
        (_) => isUpdated = true);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(isUpdated, true);

    expect(puppetStorage.hasPendingTransactions(), false);

    /// verify document has been updated

    DocumentSnapshot<String, Map<String, dynamic>>? todo;

    todosCollection.doc('1').get().then((response) => todo = response);

    puppetStorage.performNextTransaction();

    await Future.delayed(const Duration(milliseconds: 100));

    expect(todo?.id, '1');

    expect(todo?.exists, true);

    expect(todo?.data()?['name'], 'set');

    expect(todo?.data()?['completed'], true);
  });
}
