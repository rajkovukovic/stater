import 'package:flutter/material.dart';
import 'package:stater/stater/adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_snapshot.dart';
import 'package:stater/stater/query.dart';

import 'tutorial_card.dart';
import 'tutorial_screen.dart';

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
          nullLabel: 'All Tutorials',
          trueLabel: 'Published Tutorials',
          falseLabel: 'Not Published Tutorials',
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
            itemBuilder: ((context, index) => TutorialCard(
                  tutorial: data[index]!,
                  onTap: () => _editExisting(snapshots[index]),
                )),
          );
        },
      ),
    );
  }

  void _setUpStreams() {
    collectionReference = widget.adapter.collection('tutorials');
    final doc = collectionReference.doc('documentId');
    doc.delete();

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
        builder: (_) => TutorialScreen(
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
            TutorialScreen(snapshot: snapshot, onDispose: _delayedReload),
      ),
    );
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
