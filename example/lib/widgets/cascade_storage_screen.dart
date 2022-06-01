import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';
import 'package:uuid/uuid.dart';

import 'todo_card.dart';
import 'todo_screen.dart';
import 'tri_state_selector.dart';

final todoConverters = StorageOptionsWithConverter<String, Todo>(
  fromHashMap: (DocumentSnapshot snapshot) {
    return Todo.fromMap(snapshot.data() as dynamic);
  },
  toHashMap: (Todo todo) {
    return todo.toMap();
  },
);

class CascadeStorageScreen extends StatefulWidget {
  const CascadeStorageScreen({Key? key, required this.storage})
      : super(key: key);

  final Storage storage;

  @override
  State<CascadeStorageScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<CascadeStorageScreen> {
  bool? filterByPublished;

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
        title: TriStateSelector(
          onChanged: _handleFilterChanged,
          value: filterByPublished,
          nullLabel: 'All Todos',
          trueLabel: 'Completed Only',
          falseLabel: 'Uncompleted Only',
        ),
        actions: [
          IconButton(
              onPressed: _reload, icon: const Icon(Icons.replay_outlined)),
          IconButton(onPressed: _createNew, icon: const Icon(Icons.add))
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot<String, Todo>>>(
        // future: documents,
        future: Future.value(<DocumentSnapshot<String, Todo>>[]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Loading...'));
          }

          final snapshots = snapshot.data ?? [];

          if (snapshots.isEmpty) {
            return Center(
              child: ElevatedButton(
                  onPressed: _createNew, child: const Text('Create One')),
            );
          }

          final data = snapshots.map((snapshot) => snapshot.data()).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: data.length,
            itemBuilder: ((context, index) => TodoCard(
                  key: ValueKey(data[index]!.id),
                  todo: data[index]!,
                  onTap: () => _editExisting(snapshots[index]),
                )),
          );
        },
      ),
    );
  }

  void _setUpStreams() {
    collectionReference = widget.storage
        .collection<String, Todo>('todos', options: todoConverters);

    if (filterByPublished != null) {
      query = collectionReference.where(
          'completed', CompareOperator.isEqualTo, filterByPublished);
    } else {
      query = collectionReference;
    }

    documents = query.get().then((snapshot) {
      print(123);
      return snapshot.docs;
    });
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

  void _createNew() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TodoScreen(onCreate: _handleCreateNew, onDispose: _delayedReload),
      ),
    );
  }

  Future _handleCreateNew(Map<String, dynamic> data) {
    return collectionReference.add(
      Todo.fromMap(data),
      documentId: const Uuid().v4(),
    );
  }

  void _editExisting(DocumentSnapshot<String, Todo> snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TodoScreen(snapshot: snapshot, onDispose: _delayedReload),
      ),
    );
  }
}
