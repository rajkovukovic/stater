import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';
import 'package:stater_example/widgets/todos_screen_wrapper.dart';
import 'package:uuid/uuid.dart';

import 'todo_card.dart';

class TodosScreenNoConverters extends StatefulWidget {
  const TodosScreenNoConverters({
    super.key,
    required this.storage,
    this.useConverters = false,
  });

  final Storage storage;

  final bool useConverters;

  @override
  State<TodosScreenNoConverters> createState() =>
      _TodosScreenNoConvertersState();
}

class _TodosScreenNoConvertersState extends State<TodosScreenNoConverters> {
  late CollectionReference<String, Map<String, dynamic>> collectionReference;
  late Query<String, Map<String, dynamic>> query;
  late Future<List<DocumentSnapshot<String, Map<String, dynamic>>>> documents;

  bool? completedFilter;
  String searchTerm = '';

  Todo? newTodo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setUpStreams();
  }

  @override
  Widget build(BuildContext context) {
    return TodosScreenWrapper(
      appBarColor: Colors.grey,
      completedFilter: completedFilter,
      newTodoCard: _buildNewTodoCard(),
      onCreateOnePressed: () => setState(() {
        newTodo = Todo(id: const Uuid().v4(), name: '');
      }),
      onQueryChanged: _handleQueryChanged,
      onReload: _reloadData,
      searchTerm: searchTerm,
      todoBuilder: (context, todo) => todo is Map
          ? TodoCard(
              key: ValueKey(todo['id']),
              completed: todo['completed'],
              name: todo['name'],
        onCompletedChanged: (value) {
                collectionReference
                    .doc(todo['id'])
                    .update({'completed': value});
          _reloadData();
        },
        onDelete: () {
                collectionReference.doc(todo['id']).delete();
          _reloadData();
        },
        onNameChanged: (value) {
                collectionReference.doc(todo['id']).update({'name': value});
          _reloadData();
        },
            )
          : const Text('Todo must be of type Map'),
      todosFuture: documents,
    );
  }

  Widget? _buildNewTodoCard() {
    if (newTodo == null) {
      return null;
    }

    return TodoCard(
      autoFocus: true,
      key: ValueKey(newTodo!.id),
      completed: newTodo!.completed,
      name: newTodo!.name,
      onCompletedChanged: (value) => setState(() => newTodo = Todo(
          id: newTodo!.id, name: newTodo!.name, completed: value ?? false)),
      onDelete: () => setState(() => newTodo = null),
      onNameChanged: (value) {
        newTodo =
            Todo(id: newTodo!.id, name: value, completed: newTodo!.completed);

        Future.delayed(const Duration(milliseconds: 10)).then((_) {
          if (newTodo!.name.isNotEmpty || newTodo!.completed) {
            collectionReference.add(newTodo!.toJson(), documentId: newTodo!.id);
            newTodo = null;
            _reloadData();
          } else {
            newTodo = null;
            setState(() {});
          }
        });
      },
    );
  }

  void _setUpStreams() {
    collectionReference =
        widget.storage.collection<String, Map<String, dynamic>>('todos');

    query = collectionReference;

    if (completedFilter != null) {
      query = query.where(
        'completed',
        CompareOperator.isEqualTo,
        completedFilter,
      );
    }

    if (searchTerm.trim().isNotEmpty) {
      query = query.where(
        'search',
        CompareOperator.isEqualTo,
        searchTerm.trim(),
      );
    }

    documents = query.get().then((snapshot) => snapshot.docs);
  }

  void _handleQueryChanged(
      {bool? completedFilter, required String searchTerm}) {
    this.completedFilter = completedFilter;
    this.searchTerm = searchTerm;
    setState(() => _setUpStreams());
  }

  void _reloadData() => setState(() => _setUpStreams());
}
