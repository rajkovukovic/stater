import 'package:flutter/material.dart';
import 'package:stater/stater/collection_reference.dart';
import 'package:stater/stater/document_snapshot.dart';

class TutorialScreen extends StatefulWidget {
  TutorialScreen({
    Key? key,
    this.collectionRef,
    this.snapshot,
    this.onDispose,
  })  : data = snapshot?.data(),
        super(key: key) {
    assert(data != null ? true : collectionRef != null,
        'When snapshot is null, collectionRef must be provided');
  }

  final CollectionReference<String, Map<String, dynamic>>? collectionRef;
  final DocumentSnapshot<String, Map<String, dynamic>>? snapshot;
  final Map<String, dynamic>? data;
  final Function? onDispose;

  @override
  State<TutorialScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<TutorialScreen> {
  late final _titleController =
      TextEditingController(text: widget.data?['title']);
  late final _descriptionController =
      TextEditingController(text: widget.data?['description']);
  late bool _published = widget.data?['published'] ?? false;

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
          title:
              Text(widget.snapshot == null ? 'New Tutorial' : 'Edit Tutorial'),
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
                  child: Text('Title: '),
                ),
                title: TextFormField(controller: _titleController),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text('Description: '),
                ),
                title: TextFormField(controller: _descriptionController),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title:
                    const Text('Published: ', style: TextStyle(fontSize: 14)),
                value: _published,
                onChanged: (value) =>
                    value is bool ? setState(() => _published = value) : null,
              ),
              ListTile(
                  leading: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Created:  ${widget.data?['createdAt'] ?? ''}'),
              )),
              ListTile(
                  leading: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Updated:  ${widget.data?['updatedAt'] ?? ''}'),
              )),
            ],
          ),
        ));
  }

  void _handleBackButton() {
    _saveChanges();
    Navigator.of(context).pop();
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // create new document
    if (widget.data == null) {
      if (title.isNotEmpty) {
        widget.collectionRef!.add({
          'title': title,
          'description': description,
          'published': _published,
        });
      }
    }

    // edit existing document
    else {
      final prevTitle = widget.data!['title'];
      final prevDescription = widget.data!['description'];
      final prevPublished = widget.data?['published'] ?? false;

      if (prevTitle != title ||
          prevDescription != description ||
          prevPublished != _published) {
        widget.snapshot!.reference.update({
          'title': title,
          'description': description,
          'published': _published,
        });
      }

      // final changes = <String, dynamic>{};

      // if (prevTitle != title) {
      //   changes['title'] = title;
      // }

      // if (prevDescription != description) {
      //   changes['description'] = description;
      // }

      // if (prevPublished != _published) {
      //   changes['published'] = _published;
      // }

      // if (changes.isNotEmpty) {
      //   widget.snapshot!.reference.update(changes);
      // }
    }
  }

  void _delete() {
    widget.snapshot!.reference.delete();
    Navigator.of(context).pop();
  }
}
