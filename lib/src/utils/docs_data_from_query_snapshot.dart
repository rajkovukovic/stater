import 'package:stater/stater.dart';

List<T> docsDataListFromQuerySnapshot<ID, T>(QuerySnapshot<ID, T> snapshot) {
  return snapshot.docs.map((doc) => doc.data()!).toList();
}

Map<ID, T> docsDataMapFromQuerySnapshot<ID, T>(QuerySnapshot<ID, T> snapshot) {
  return snapshot.docs.fold<Map<ID, T>>({}, (acc, doc) {
    acc[doc.id] = doc.data() as T;
    return acc;
  });
}
