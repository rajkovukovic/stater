import 'dart:convert';

class Todo {
  final String id;
  final String name;
  final bool completed;

  const Todo({
    required this.id,
    required this.name,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      completed: map['completed'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Todo.fromJson(String source) => Todo.fromMap(json.decode(source));
}
