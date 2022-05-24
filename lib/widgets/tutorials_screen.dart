import 'package:flutter/material.dart';
import 'package:stater/custom/get_storage_adapter.dart';
import 'package:stater/custom/rest_adapter.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

import 'tutorial_card.dart';
import 'tutorial_screen.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({Key? key}) : super(key: key);

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final restMachine = RestAdapter('https://jsonplaceholder.typicode.com');

  final getStorageMachine = GetStorageAdapter('DB');

  bool isRest = false;

  late CollectionReference<String, Map<String, dynamic>> collectionRef;

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
        title: const Text('Users'),
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
    collectionRef =
        (isRest ? restMachine : getStorageMachine).collection('users');

    documents = collectionRef.snapshots().map((snapshot) => snapshot.docs);
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
            collectionRef: collectionRef, onDispose: _delayedReload),
      ),
    );
  }

  void _editExisting(DocumentSnapshot<String, Map<String, dynamic>> snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TutorialScreen(snapshot: snapshot, onDispose: _delayedReload),
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
