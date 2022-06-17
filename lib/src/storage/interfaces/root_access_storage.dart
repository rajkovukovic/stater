import 'package:stater/stater.dart';

/// has methods for adding and removing collections of data
/// and methods for adding or removing multiple collections
abstract class RootAccessStorage extends Storage {
  /// removes all documents and all collections
  Future<void> removeAllCollections();

  /// removes a collection and all its documents
  Future<void> removeCollection(String collectionName);

  /// removes all documents from a collection,
  /// but leaves empty collection behind
  Future<void> removeAllDocumentsInCollection(String collectionName);

  /// inserts all [documents] to a collection and overwrites existing ones
  Future<void> insertToCollection(
    String collectionName,
    Map<String, dynamic> documents,
  );

  /// removes all collection documents and inserts all from [documents] param
  Future<void> replaceCollection(
    String collectionName,
    Map<String, dynamic> documents,
  );

  /// merges [collections] map into existing data
  ///
  /// existing documents will be overwritten
  Future<void> insertData(Map<String, dynamic> collections);

  /// returns whole collection
  Future<Map<String, dynamic>> getCollectionData(String collectionName);

  /// returns whole database
  Future<Map<String, Map<String, dynamic>>> getAllData();
}
