import 'package:stater/stater.dart';

/// operates on a collection
///
/// has collectionName property
abstract class CollectionOperation extends Operation {
  final String collectionName;

  CollectionOperation({
    DateTime? timestamp,
    required this.collectionName,
  }) {
    super.timestamp = timestamp ?? DateTime.now();
  }
}
