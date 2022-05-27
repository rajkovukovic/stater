library stater;

import 'package:stater/custom/get_storage_adapter.dart';
import 'package:stater/custom/rest_adapter.dart';
import 'package:stater/stater/cascade_adapter/cascade_adapter.dart';
import 'package:stater/stater/query.dart';

bool doesTutorialMatchQuery(Object? element, Query query) {
  if (query.compareOperations.isEmpty) {
    return true;
  } else if (query.compareOperations.length == 1 &&
      query.compareOperations.first.compareOperator ==
          CompareOperator.isEqualTo &&
      query.compareOperations.first.field == 'published' &&
      element is Map) {
    return (element['published'] ?? false) ==
        query.compareOperations.first.valueToCompareTo;
  } else {
    throw 'Can only query a map by "published" field for equality';
  }
}

final restDelegate = RestDelegate(
  id: 'rest-server-mongodb',
  endpoint: 'http://localhost:3030',
);

final getStorageDelegate = GetStorageDelegate(
  id: 'get-storage',
  storagePrefix: 'DB',
  doesMatchQuery: doesTutorialMatchQuery,
);

final stater = CascadeAdapter([
  restDelegate,
  getStorageDelegate,
]);
