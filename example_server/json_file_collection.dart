import 'dart:convert';
import 'dart:io';

class JsonFileCollection {
  late final Future _initFuture;
  late Map<String, Map<String, dynamic>> data = {};
  final String collectionName;

  static String filePath(collectionName) => './data/$collectionName.json';

  JsonFileCollection(this.collectionName) {
    _init();
  }

  _init() {
    _initFuture = File(filePath(collectionName))
        .readAsString()
        .then(jsonDecode)
        .then((value) => data = value.cast<String, Map<String, dynamic>>())
        .catchError((error) =>
            print('Error parsing file "${filePath(collectionName)}": $error'));
  }

  static Future<JsonFileCollection> initialized(String collectionName) {
    final instance = JsonFileCollection(collectionName);
    return instance.getData().then((_) => instance);
  }

  Future<Map<String, Map<String, dynamic>>> getData() async {
    await _initFuture;
    return {};
  }

  Future saveData() {
    return File(filePath(collectionName))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}
