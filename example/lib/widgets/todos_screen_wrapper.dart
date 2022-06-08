import 'package:flutter/material.dart';

import 'tri_state_selector.dart';

class TodosScreenWrapper extends StatefulWidget {
  const TodosScreenWrapper({
    this.appBarColor,
    this.completedFilter,
    super.key,
    this.newTodoCard,
    this.onCreateNewPressed,
    this.onQueryChanged,
    this.onReload,
    this.searchTerm = '',
    required this.todoBuilder,
    required this.todosFuture,
  });

  final Color? appBarColor;

  final bool? completedFilter;

  final Widget? newTodoCard;

  final void Function()? onCreateNewPressed;

  final void Function({bool? completedFilter, required String searchTerm})?
      onQueryChanged;

  final void Function()? onReload;

  final String searchTerm;

  final Widget Function(BuildContext context, dynamic todo) todoBuilder;

  final Future<dynamic> todosFuture;

  @override
  State<TodosScreenWrapper> createState() => _TodosScreenWrapper();
}

class _TodosScreenWrapper extends State<TodosScreenWrapper> {
  final textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (textController.text != widget.searchTerm) {
      textController.text = widget.searchTerm;
    }
  }

  @override
  void dispose() {
    super.dispose();
    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.appBarColor,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TriStateSelector(
              onChanged: (value) => _changeQuery(
                  completedFilter: value, searchTerm: widget.searchTerm),
              dropdownColor: Colors.grey,
              value: widget.completedFilter,
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
                  onChanged: (value) => _changeQuery(
                      completedFilter: widget.completedFilter,
                      searchTerm: value),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: widget.onReload,
              icon: const Icon(Icons.replay_outlined)),
          IconButton(
              onPressed: widget.onCreateNewPressed, icon: const Icon(Icons.add))
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: widget.todosFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          }

          Widget? messageWidget;

          if (snapshot.connectionState == ConnectionState.waiting) {
            messageWidget = const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Loading...')));
          }

          final snapshots = snapshot.data ?? [];

          if (snapshots.isEmpty) {
            final thereIsQuery = widget.completedFilter != null ||
                widget.searchTerm.trim().isNotEmpty;

            messageWidget = thereIsQuery
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('no results...'),
                        ),
                        ElevatedButton(
                            onPressed: _clearQuery,
                            child: const Text('Clear filters'))
                      ],
                    ),
                  )
                : widget.newTodoCard == null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: ElevatedButton(
                            onPressed: widget.onCreateNewPressed,
                            child: const Text('Create First Todo')),
                      )
                    : null;
          }

          final data = messageWidget == null
              ? snapshots.map((snapshot) => snapshot.data()).toList()
              : [null];

          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(
                indent: 60, height: 1, thickness: 1, color: Colors.black26),
            itemCount: data.length + (widget.newTodoCard != null ? 1 : 0),
            itemBuilder: (context, index) => index < data.length
                ? messageWidget ?? widget.todoBuilder(context, data[index])
                : widget.newTodoCard!,
          );
        },
      ),
    );
  }

  void _changeQuery({
    required bool? completedFilter,
    required String searchTerm,
  }) {
    if (widget.completedFilter != completedFilter ||
        widget.searchTerm != searchTerm) {
      widget.onQueryChanged
          ?.call(completedFilter: completedFilter, searchTerm: searchTerm);
    }
  }

  void _clearQuery() {
    textController.clear();
    _changeQuery(
      completedFilter: null,
      searchTerm: '',
    );
  }
}
