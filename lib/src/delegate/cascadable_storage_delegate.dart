import 'package:stater/stater.dart';

abstract class CascadableStorageDelegate extends StorageDelegate {
  final String id;
  // final QueryMatcher doesMatchQuery;
  // final QueryCompareGenerator? generateCompareFromQuery;

  CascadableStorageDelegate({
    required this.id,
    // required this.doesMatchQuery,
    // this.generateCompareFromQuery,
  });
}
