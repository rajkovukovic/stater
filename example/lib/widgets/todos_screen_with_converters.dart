import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';
import 'package:stater_example/widgets/todos_screen_wrapper.dart';
import 'package:uuid/uuid.dart';

import 'todo_card.dart';

class TodosScreenWithConverters extends StatefulWidget {
  const TodosScreenWithConverters({
    super.key,
    required this.storage,
    this.useConverters = false,
  });

  final Storage storage;

  final bool useConverters;

  @override
  State<TodosScreenWithConverters> createState() =>
      _TodosScreenWithConvertersState();
}

class _TodosScreenWithConvertersState extends State<TodosScreenWithConverters> {
  late CollectionReference<String, Todo> collectionReference;
  late Query<String, Todo> query;
  late Future<List<DocumentSnapshot<String, Todo>>> documents;

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
      completedFilter: completedFilter,
      newTodoCard: _buildNewTodoCard(),
      onCreateOnePressed: () => setState(() {
        newTodo = Todo(id: const Uuid().v4(), name: '');
      }),
      onCreateManyPressed: _handleCreateMany,
      onRemoveAllPressed: _handleRemoveAll,
      onQueryChanged: _handleQueryChanged,
      onReload: _reloadData,
      searchTerm: searchTerm,
      todoBuilder: (context, todo) => TodoCard(
        key: ValueKey(todo.id),
        completed: todo.completed,
        name: todo.name,
        onCompletedChanged: (value) async {
          await collectionReference.doc(todo.id).update({'completed': value});
          _reloadData();
        },
        onDelete: () async {
          await collectionReference.doc(todo.id).delete();
          _reloadData();
        },
        onNameChanged: (value) async {
          await collectionReference.doc(todo.id).update({'name': value});
          _reloadData();
        },
      ),
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

        Future.delayed(const Duration(milliseconds: 10)).then((_) async {
          if (newTodo!.name.isNotEmpty || newTodo!.completed) {
            await collectionReference.add(newTodo!, documentId: newTodo!.id);
            newTodo = null;
            _reloadData();
          } else {
            newTodo = null;
          }
          setState(() {});
        });
      },
    );
  }

  void _setUpStreams() {
    collectionReference = widget.storage
        .collection<String, Todo>('todos')
        .withConverters(todoConverters);

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

    final req = query.get();

    documents = req.then((snapshot) {
      return snapshot.docs;
    });

    // print('::: loading data');
    // req.then((res) {
    //   print('::: data');
    //   print(res);
    // }).catchError((error) {
    //   print('::: error');
    //   print(error);
    // });
  }

  void _handleQueryChanged({
    bool? completedFilter,
    required String searchTerm,
  }) {
    this.completedFilter = completedFilter;
    this.searchTerm = searchTerm;
    setState(() => _setUpStreams());
  }

  void _reloadData() => setState(() => _setUpStreams());

  void _handleCreateMany() {
    documents = widget.storage
        .serviceRequest('createManyTodos', [
          const Uuid().v4(),
          const Uuid().v4(),
          const Uuid().v4(),
        ])
        .then((_) => Future.delayed(const Duration(milliseconds: 1000)))
        .then((_) => []);

    documents.then((_) => setState(() => _setUpStreams()));

    setState(() {});
  }

  void _handleRemoveAll() async {
    await widget.storage.serviceRequest('removeAllTodos', null);
    _reloadData();
  }
}
