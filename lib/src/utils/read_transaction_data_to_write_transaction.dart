import 'package:stater/stater.dart';

ExclusiveTransaction readTransactionDataToWriteTransaction({
  required Transaction readTransaction,
  required List readData,
  required Set<String> excludeDelegateWithIds,
}) {
  final operations = <Operation>[];

  for (var i = 0; i < readTransaction.operations.length; i++) {
    final operation = readTransaction.operations[i];
    final snapshot = readData[i];

    // data should be a
    switch (operation.operationType) {
      case OperationType.getDocument:
        if (snapshot is! DocumentSnapshot) {
          throw 'data[$i] should be a DocumentSnapshot. '
              'Got ${snapshot.runtimeType} instead.';
        } else if (snapshot.exists) {
          operations.add(
            SetOperation(
              data: snapshot.data() as dynamic,
              documentId: snapshot.id as dynamic,
              collectionName: snapshot.reference.collectionName,
            ),
          );
        }
        break;
      case OperationType.getQuery:
        if (snapshot is! QuerySnapshot) {
          throw 'data[$i] should be a DocumentSnapshot. '
              'Got ${snapshot.runtimeType} instead.';
        } else {
          operations.addAll(snapshot.docs.map(
            (doc) => SetOperation(
              data: doc.data() as dynamic,
              documentId: doc.id as dynamic,
              collectionName: doc.reference.collectionName,
            ),
          ));
        }
        break;
      default:
        throw 'readTransactionDataToWriteTransaction can convert only '
            'transactions where all operations are ReadOperation';
    }
  }

  return ExclusiveTransaction(
    excludeDelegateWithIds: excludeDelegateWithIds,
    id: readTransaction.id,
    operations: operations,
  );
}
