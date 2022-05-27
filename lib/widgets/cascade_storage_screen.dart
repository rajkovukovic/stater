import 'package:flutter/material.dart';
import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';
import 'package:stater/widgets/tri_state_selector.dart';
import 'package:uuid/uuid.dart';

import 'todo_card.dart';
import 'todo_screen.dart';

class CascadeStorageScreen extends StatefulWidget {
  const CascadeStorageScreen({Key? key, required this.adapter})
      : super(key: key);

  final Adapter adapter;

  @override
  State<CascadeStorageScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<CascadeStorageScreen> {
  bool? filterByPublished;

  late CollectionReference<String, Map<String, dynamic>> collectionReference;

  late Query<String, Map<String, dynamic>> query;

  late Stream<List<DocumentSnapshot<String, Map<String, dynamic>>>> documents;

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
      body: StreamBuilder<List<DocumentSnapshot<String, Map<String, dynamic>>>>(
        stream: documents,
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
                  key: ValueKey(data[index]!['_id']),
                  todo: data[index]!,
                  onTap: () => _editExisting(snapshots[index]),
                )),
          );
        },
      ),
    );
  }

  void _setUpStreams() {
    collectionReference = widget.adapter.collection('todos');

    if (filterByPublished != null) {
      query = collectionReference.where(
          'completed', CompareOperator.isEqualTo, filterByPublished);
    } else {
      query = collectionReference;
    }

    documents = query.snapshots().map((snapshot) => snapshot.docs);
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
    return collectionReference.doc(const Uuid().v4()).set(data);
  }

  void _editExisting(DocumentSnapshot<String, Map<String, dynamic>> snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TodoScreen(snapshot: snapshot, onDispose: _delayedReload),
      ),
    );
  }
}

bool doesTutorialMatchQuery(Object? element, Query query) {
  if (query.compareOperations.isEmpty) {
    return true;
  } else if (query.compareOperations.length == 1 &&
      query.compareOperations.first.compareOperator ==
          CompareOperator.isEqualTo &&
      query.compareOperations.first.field == 'published' &&
      element is Map) {
    return (element['published'] ?? false) ==
        query.compareOperations.first.valueToCompareTo;
  } else {
    throw 'Can only query a map by "published" field for equality';
  }
}
