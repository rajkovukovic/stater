import 'collection_operation.dart';

abstract class OperationWithDocumentId extends CollectionOperation {
  final String documentId;

  OperationWithDocumentId({
    super.completer,
    required this.documentId,
    super.timestamp,
    required super.collectionName,
  });
}
