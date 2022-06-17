import 'package:stater/stater.dart';

class Todo {
  final String id;
  final String name;
  final bool completed;

  const Todo({
    required this.id,
    required this.name,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'completed': completed,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> map) {
    return Todo(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

final todoConverters = Converters<String, Todo>(
  (snapshot) => Todo.fromJson(snapshot.data()!),
  (todo) => todo.toJson(),
);
