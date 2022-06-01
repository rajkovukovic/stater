import 'package:flutter/material.dart';
import 'package:stater_example/models/todo.dart';

class TodoCard extends StatelessWidget {
  const TodoCard({
    Key? key,
    required this.todo,
    this.onTap,
  }) : super(key: key);

  final Todo todo;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final completed = todo.completed == true;
    return Card(
      color: Colors.lightBlue.shade100,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                todo.name,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              SelectableText(
                completed ? 'completed' : 'not completed',
                style: TextStyle(color: completed ? Colors.blueAccent : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
