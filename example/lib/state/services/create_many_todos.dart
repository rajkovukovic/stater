import 'package:stater/stater.dart';
import 'package:uuid/uuid.dart';

void createManyTodos(Storage storage, dynamic params) async {
  final int createCount = params;

  final todosCollection = storage.collection('todos');

  final existingTodos = (await todosCollection.get()).docs;

  final existingNames = existingTodos.fold<Set<String>>(
      {},
      (acc, doc) => acc
        ..add((doc.data() as Map<String, dynamic>)['name']
            .replaceAll(RegExp(r"\s+"), "")));

  int nextTodoNumber = 1;

  for (var i = 0; i < createCount; i++) {
    while (existingNames.contains('todo$nextTodoNumber')) {
      nextTodoNumber++;
    }

    final todo = {'name': 'Todo $nextTodoNumber', 'completed': false};

    await todosCollection.add(
      todo,
      documentId: const Uuid().v4(),
    );

    nextTodoNumber++;
  }
}
