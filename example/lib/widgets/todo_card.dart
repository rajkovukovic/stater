import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TodoCard extends StatefulWidget {
  const TodoCard({
    this.autoFocus = false,
    required Key key,
    required this.name,
    required this.completed,
    this.onCompletedChanged,
    this.onDelete,
    this.onNameChanged,
  }) : super(key: key);

  final bool autoFocus;
  final String name;
  final bool completed;
  final void Function(bool?)? onCompletedChanged;
  final void Function()? onDelete;
  final void Function(String)? onNameChanged;

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  final focusNode = FocusNode();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoFocus) {
        focusNode.requestFocus();
      }
    });

    focusNode.addListener(() {
      if (!focusNode.hasPrimaryFocus) {
        widget.onNameChanged?.call(textController.text);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (textController.text != widget.name) {
      textController.text = widget.name;
    }
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
    textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: widget.key,
      dragStartBehavior: DragStartBehavior.start,
      closeOnScroll: true,
      groupTag: 'todo-card',
      endActionPane: ActionPane(
        // A motion is a widget used to control how the pane animates.
        motion: const StretchMotion(),

        // A pane can dismiss the Slidable.
        dismissible:
            DismissiblePane(onDismissed: () => widget.onDelete?.call()),

        // All actions are defined in the children parameter.
        children: [
          // A SlidableAction can have an icon and/or a label.
          SlidableAction(
            autoClose: true,
            onPressed: (_) => widget.onDelete?.call(),
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Press or Slide all the way to delete',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  widget.onCompletedChanged?.call(!widget.completed);
                },
                icon: Icon(widget.completed
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined)),
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: '...',
                  isDense: true,
                ),
                onEditingComplete: () =>
                    widget.onNameChanged?.call(textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
