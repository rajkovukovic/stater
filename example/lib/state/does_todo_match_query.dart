import 'package:stater/stater.dart';

bool doesTodoMatchQuery(Map<String, dynamic> todo, Query query) {
  if (query.compareOperations.isEmpty) {
    return true;
  } else {
    for (var operation in query.compareOperations) {
      if (operation.compareOperator == CompareOperator.isEqualTo &&
          {'completed', 'search'}.contains(operation.field)) {
        if (operation.field == 'completed') {
          if (operation.valueToCompareTo == (todo['completed'] ?? false)) {
            continue;
          } else {
            return false;
          }
        } else {
          if ((todo['name'] as String? ?? '')
              .toLowerCase()
              .contains(operation.valueToCompareTo.toString().toLowerCase())) {
            continue;
          } else {
            return false;
          }
        }
      } else {
        throw 'Todo query can contain "completed" and "search" fields only';
      }
    }

    return true;
  }
}
