import 'package:stater/stater.dart';

abstract class CascadableStorage extends Storage {
  String id;
  // final QueryMatcher doesMatchQuery;
  // final QueryCompareGenerator? generateCompareFromQuery;

  CascadableStorage({
    required this.id,
    // required this.doesMatchQuery,
    // this.generateCompareFromQuery,
  });
}
