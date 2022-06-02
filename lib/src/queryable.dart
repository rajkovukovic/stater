import 'package:stater/src/query.dart';

/// instances of this interface implement doesMatchQuery
/// and generateCompareFromQuery methods
abstract class Queryable {
  bool doesMatchQuery(Query query);

  int Function(T a, T b)? generateCompareFromQuery<T>(Query query);
}
