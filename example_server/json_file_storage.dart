import 'package:uuid/uuid.dart';

import 'json_file_collection.dart';

class JsonFileStorage {
  final _existingCollections = <String, Future<JsonFileCollection>>{};

  Future<JsonFileCollection> _getJsonCollection(String collectionName) {
    return _existingCollections.putIfAbsent(
        collectionName, () => JsonFileCollection.initialized(collectionName));
  }

  /// creates a new document
  Future<Map<String, dynamic>?> internalAddDocument({
    required String collectionName,
    required Map<String, dynamic> documentData,
    String? documentId,
  }) async {
    final collectionData = await _getJsonCollection(collectionName);

    final dynamic id = documentId ?? const Uuid().v4();

    collectionData.data[id] = documentData as dynamic;

    await collectionData.saveData();

    return {...documentData, 'id': id};
  }

  /// deletes the document
  Future<void> internalDeleteDocument({
    required String collectionName,
    required String documentId,
  }) async {
    final collectionData = await _getJsonCollection(collectionName);

    collectionData.data.remove(documentId);

    await collectionData.saveData();
  }

  /// Reads the document
  Future<Map<String, dynamic>?> internalGetDocument({
    required String collectionName,
    required String documentId,
  }) async {
    final collectionData = await _getJsonCollection(collectionName);

    return collectionData.data[documentId];
  }

  /// Reads the document
  Future<List<Map<String, dynamic>>> internalGetQuery(
      {required String collectionName, Map<String, dynamic>? query}) async {
    final collectionData = await _getJsonCollection(collectionName);

    return collectionData.data.entries.fold<List<Map<String, dynamic>>>(
      [],
      (acc, entry) => acc..add({...entry.value, 'id': entry.key}),
    );
  }

  /// Reads the document
  Future<void> internalReplaceCollection(
      {required String collectionName, Map<String, dynamic>? data}) async {
    final collectionData = await _getJsonCollection(collectionName);

    collectionData.data = (data ?? {}).cast<String, Map<String, dynamic>>();

    await collectionData.saveData();
  }

  /// performs specific operation(s) that can not be described using
  /// the existing CRUD operations
  Future internalServiceRequest(String serviceName, dynamic params) {
    throw Exception('This server does not implement service requests yet');
  }

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  Future<void> internalSetDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> documentData,
  }) async {
    final collectionData = await _getJsonCollection(collectionName);

    collectionData.data[documentId.toString()] = documentData;

    await collectionData.saveData();
  }

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> internalUpdateDocument<ID extends Object?>({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> documentData,
  }) async {
    final collectionData = await _getJsonCollection(collectionName);

    collectionData.data
        .update(documentId.toString(), (value) => {...value, ...documentData});

    await collectionData.saveData();
  }
}
