import 'package:stater/stater.dart';

/// operates on a collection
///
/// has collectionName property
abstract class CollectionOperation extends Operation {
  final String collectionName;

  CollectionOperation({
    super.completer,
    required this.collectionName,
    DateTime? timestamp,
  }) : super(timestamp: timestamp);
}
