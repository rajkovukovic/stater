import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';
import 'package:uuid/uuid.dart';

import 'todo_card.dart';
import 'todo_screen.dart';
import 'tri_state_selector.dart';

final todoConverters = Converters<String, Todo>(
  (snapshot) => Todo.fromMap(snapshot.data()!),
  (todo) => todo.toMap(),
);

class CascadeStorageScreen extends StatefulWidget {
  const CascadeStorageScreen({
    super.key,
    required this.storage,
    this.useConverters = false,
  });

  final Storage storage;

  final bool useConverters;

  @override
  State<CascadeStorageScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<CascadeStorageScreen> {
  bool? filterByPublished;

  String searchTerm = '';

  final textController = TextEditingController();

  late CollectionReference<String, Todo> collectionReference;

  late Query<String, Todo> query;

  late Future<List<DocumentSnapshot<String, Todo>>> documents;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setUpStreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.grey,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TriStateSelector(
              onChanged: _handleFilterChanged,
              dropdownColor: Colors.grey,
              value: filterByPublished,
              nullLabel: 'All Todos',
              trueLabel: 'Completed',
              falseLabel: 'Uncompleted',
              textStyle: const TextStyle(color: Colors.white),
            ),
            Expanded(
              child: TextField(
                  controller: textController,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(top: 15),
                    border: InputBorder.none,
                    fillColor: Colors.white,
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                  ),
                  onChanged: _changeSearchTerm,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _reload, icon: const Icon(Icons.replay_outlined)),
          IconButton(
              onPressed: _openCreateTodoForm, icon: const Icon(Icons.add))
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot<String, Todo>>>(
        future: documents,
        // future: Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Loading...'));
          }

          final snapshots = snapshot.data ?? [];

          if (snapshots.isEmpty) {
            final thereIsQuery =
                filterByPublished != null || searchTerm.trim().isNotEmpty;

            return Center(
              child: thereIsQuery
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('no results...'),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              _handleFilterChanged(null);
                              _changeSearchTerm('');
                              textController.clear();
                            },
                            child: const Text('Clear filters'))
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _openCreateTodoForm,
                      child: const Text('Create One')),
            );
          }

          final data = snapshots.map((snapshot) => snapshot.data()).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: data.length,
            itemBuilder: ((context, index) => TodoCard(
                  key: ValueKey(data[index]!.id),
                  todo: data[index]!,
                  onTap: () => _openEditTodoForm(snapshots[index]),
                )),
          );
        },
      ),
    );
  }

  void _changeSearchTerm(String nextSearchTerm) {
    searchTerm = nextSearchTerm;
    _setUpStreams();
    setState(() {});
  }

  void _setUpStreams() {
    collectionReference = widget.storage
        .collection<String, Todo>('todos')
        .withConverters(todoConverters);

    query = collectionReference;

    if (filterByPublished != null) {
      query = query.where(
        'completed',
        CompareOperator.isEqualTo,
        filterByPublished,
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

  _handleFilterChanged(bool? value) {
    setState(() {
      filterByPublished = value;
      _setUpStreams();
    });
  }

  void _reload() {
    setState(() => _setUpStreams());
  }

  void _delayedReload() {
    Future.delayed(const Duration(milliseconds: 100)).then((_) => _reload());
  }

  void _openCreateTodoForm() {
    TodoScreen.showAsModal(
        context: context, onCreate: _createTodo, onDispose: _delayedReload);
  }

  void _openEditTodoForm(DocumentSnapshot<String, Todo> snapshot) {
    TodoScreen.showAsModal(
        context: context, snapshot: snapshot, onDispose: _delayedReload);
  }

  Future _createTodo(Map<String, dynamic> data) {
    return collectionReference.add(
      Todo.fromMap(data),
      documentId: const Uuid().v4(),
    );
  }
}
