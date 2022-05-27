import 'package:flutter/material.dart';
import 'package:stater/custom/get_storage_adapter.dart';
import 'package:stater/custom/rest_adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';

import 'todo_card.dart';
import 'todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final restMachine = RestAdapter(
    RestDelegate(
      id: 'rest-server-mongodb',
      endpoint: 'http://localhost:6868/api',
    ),
  );

  final getStorageMachine = GetStorageAdapter(
    GetStorageDelegate(
      id: 'get-storage',
      storagePrefix: 'DB',
      doesMatchQuery: doesTutorialMatchQuery,
    ),
  );

  bool isRest = false;

  bool? filterByPublished;

  late CollectionReference<String, Map<String, dynamic>> collectionReference;

  late Query<String, Map<String, dynamic>> query;

  late Stream<List<DocumentSnapshot<String, Map<String, dynamic>>>> documents;

  @override
  void initState() {
    super.initState();
    _setUpStreams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TriStateSelector(
          onChanged: _handleFilterChanged,
          value: filterByPublished,
          nullLabel: 'All Tutorials',
          trueLabel: 'Published Tutorials',
          falseLabel: 'Not Published Tutorials',
        ),
        actions: [
          IconButton(
              onPressed: _toggleStateMachine,
              icon: Icon(isRest ? Icons.network_wifi : Icons.computer)),
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
                  todo: data[index]!,
                  onTap: () => _editExisting(snapshots[index]),
                )),
          );
        },
      ),
    );
  }

  void _setUpStreams() {
    collectionReference =
        (isRest ? restMachine : getStorageMachine).collection('tutorials');

    if (filterByPublished != null) {
      query = collectionReference.where(
          'published', CompareOperator.isEqualTo, filterByPublished);
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
            TodoScreen(
            onCreate: _handleCreateNew, onDispose: _delayedReload),
      ),
    );
  }

  Future _handleCreateNew(Map<String, dynamic> data) {
    return collectionReference.add(data);
  }

  void _editExisting(DocumentSnapshot<String, Map<String, dynamic>> snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TodoScreen(snapshot: snapshot, onDispose: _delayedReload),
      ),
    );
  }

  _toggleStateMachine() {
    setState(() {
      isRest = !isRest;
      _setUpStreams();
    });
  }
}

class TriStateSelector extends StatelessWidget {
  final bool? value;
  final void Function(bool?)? onChanged;
  final String? nullLabel;
  final String? trueLabel;
  final String? falseLabel;

  const TriStateSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.nullLabel,
    this.trueLabel,
    this.falseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<bool?>(
      value: value,
      onChanged: onChanged,
      items: [
        DropdownMenuItem(value: null, child: Text(nullLabel ?? 'null')),
        DropdownMenuItem(value: true, child: Text(trueLabel ?? 'true')),
        DropdownMenuItem(value: false, child: Text(falseLabel ?? 'false')),
      ],
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
