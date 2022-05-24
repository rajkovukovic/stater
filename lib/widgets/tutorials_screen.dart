import 'package:flutter/material.dart';

import '../state_machine/adapters/get_storage_adapter/get_storage_adapter.dart';
import '../state_machine/adapters/rest_adapter/rest_adapter.dart';
import '../state_machine/collection_reference.dart';
import '../state_machine/document_snapshot.dart';
import '../state_machine/stater.dart';
import 'tutorial_card.dart';
import 'tutorial_screen.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({Key? key}) : super(key: key);

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final restMachine = StateMachine(RestAdapter<String, Map<String, dynamic>>(
      'http://100.81.80.104:6868/api'));

  final getStorageMachine =
      StateMachine(GetStorageAdapter<String, Map<String, dynamic>>('DB'));

  bool isRest = true;

  late CollectionReference<String, Map<String, dynamic>> collectionRef =
      (isRest ? restMachine : getStorageMachine).collection('tutorials');

  late Stream<List<DocumentSnapshot<String, Map<String, dynamic>>>> documents =
      collectionRef.snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorials'),
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
                  onPressed: _createNew,
                  child: const Text('Create One')),
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

  void _reload() {
    setState(() {
      documents = collectionRef.snapshots();
    });
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
      print('isRest: $isRest');
      collectionRef =
          (isRest ? restMachine : getStorageMachine).collection('tutorials');
      documents = collectionRef.snapshots();
    });
  }
}
