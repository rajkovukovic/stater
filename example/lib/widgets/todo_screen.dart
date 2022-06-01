import 'package:flutter/material.dart';
import 'package:stater/stater.dart';
import 'package:stater_example/models/todo.dart';

class TodoScreen extends StatefulWidget {
  TodoScreen({
    Key? key,
    this.onCreate,
    this.snapshot,
    this.onDispose,
  })  : data = snapshot?.data(),
        super(key: key) {
    assert(data != null ? true : onCreate != null,
        'When snapshot is null, onCreate must be provided');
  }

  final Function(Map<String, dynamic>)? onCreate;
  final DocumentSnapshot<String, Todo>? snapshot;
  final Todo? data;
  final Function? onDispose;

  @override
  State<TodoScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<TodoScreen> {
  late final _nameController = TextEditingController(text: widget.data?.name);
  late bool _completed = widget.data?.completed ?? false;

  @override
  void dispose() {
    _saveChanges();
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBackButton),
          title: Text(widget.snapshot == null ? 'New Todo' : 'Edit Todo'),
          actions: [
            if (widget.snapshot != null)
              IconButton(onPressed: _delete, icon: const Icon(Icons.delete))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text('Name: '),
                ),
                title: TextFormField(controller: _nameController),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title:
                    const Text('Completed: ', style: TextStyle(fontSize: 14)),
                value: _completed,
                onChanged: (value) =>
                    value is bool ? setState(() => _completed = value) : null,
              ),
              // ListTile(
              //     leading: Padding(
              //   padding: const EdgeInsets.only(top: 4.0),
              //   child: Text('Created:  ${widget.data?['createdAt'] ?? ''}'),
              // )),
              // ListTile(
              //     leading: Padding(
              //   padding: const EdgeInsets.only(top: 4.0),
              //   child: Text('Updated:  ${widget.data?['updatedAt'] ?? ''}'),
              // )),
            ],
          ),
        ));
  }

  void _handleBackButton() {
    // _saveChanges();
    Navigator.of(context).pop();
  }

  void _saveChanges() {
    final name = _nameController.text.trim();

    // create new document
    if (widget.data != null) {
      final prevName = widget.data!.name;
      final prevCompleted = widget.data!.completed;

      if (prevName != name || prevCompleted != _completed) {
        widget.snapshot!.reference.set(Todo.fromMap({
          'id': widget.data!.id,
          'name': name,
          'completed': _completed,
        }));
      }
    }

    // edit existing document
    else {
      if (name.isNotEmpty) {
        widget.onCreate!({
          'name': name,
          'completed': _completed,
        });
      }
    }
  }

  void _delete() {
    widget.snapshot!.reference.delete();
    Navigator.of(context).pop();
  }
}
