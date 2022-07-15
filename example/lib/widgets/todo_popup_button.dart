import 'package:flutter/material.dart';

class TodoPopupButton extends StatelessWidget {
  final void Function()? onCreateOnePressed;
  final void Function()? onCreateManyPressed;
  final void Function()? onRemoveAllPressed;

  const TodoPopupButton({
    super.key,
    this.onCreateOnePressed,
    this.onCreateManyPressed,
    this.onRemoveAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoPopupOption>(
      onSelected: _handlePressed,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: TodoPopupOption.createOneTodo,
          child: Text('Create a Todo'),
        ),
        const PopupMenuItem(
          value: TodoPopupOption.createManyTodos,
          child: Text('Create Many Todos'),
        ),
        const PopupMenuItem(
          value: TodoPopupOption.removeAllTodos,
          child: Text('Remove All Todos'),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.more_vert_rounded),
      ),
    );
  }

  _handlePressed(TodoPopupOption value) {
    switch (value) {
      case TodoPopupOption.createOneTodo:
        onCreateOnePressed?.call();
        break;
      case TodoPopupOption.createManyTodos:
        onCreateManyPressed?.call();
        break;
      case TodoPopupOption.removeAllTodos:
        onRemoveAllPressed?.call();
        break;
    }
  }
}

enum TodoPopupOption {
  createOneTodo,
  createManyTodos,
  removeAllTodos,
}
