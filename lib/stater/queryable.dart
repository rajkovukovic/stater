import 'package:stater/stater/query.dart';

/// instances of this interface implement doesMatchQuery
/// and generateCompareFromQuery methods
abstract class Queryable {
  bool doesMatchQuery(Query query);

  int Function(Queryable a, Queryable b)? generateCompareFromQuery(Query query);
}
