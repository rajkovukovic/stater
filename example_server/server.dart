// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'json_file_storage.dart';

Future main() async {
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  // Platform.environment['PORT']
  const port = 54123;

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      // .add(_staticHandler)
      // If a corresponding file is not found, send requests to a `Router`
      .add(_router);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests()
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
}

// Serve files from the file system.
// final _staticHandler =
//     shelf_static.createStaticHandler('public', defaultDocument: 'index.html');

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..post('/api/replaceCollection/<collectionName>', _replaceCollectionHandler)
  ..post('/api/serviceRequest/<serviceName>', _serviceRequestHandler)
  ..put('/api/<collectionName>/<documentId>', _setDocumentHandler)
  ..post('/api/<collectionName>', _createDocumentHandler)
  ..patch('/api/<collectionName>/<documentId>', _updateDocumentHandler)
  ..delete('/api/<collectionName>/<documentId>', _deleteDocumentHandler)
  ..get('/api/<collectionName>/<documentId>', _getDocumentHandler)
  ..get('/api/<collectionNameWithQuery>', _getQueryHandler)
  ..get('/*', (_) => Response.notFound('404'));

final jsonFileStorage = JsonFileStorage();

Future<Response> _getDocumentHandler(
  Request request,
  String collectionName,
  String documentId,
) async {
  if (collectionName.isEmpty) {
    return Response.badRequest(
        body: 'Can not read collectionName from the request');
  }

  if (documentId.isEmpty) {
    return Response.badRequest(
        body: 'Can not read documentId from the request');
  }

  final document = await jsonFileStorage.internalGetDocument(
    collectionName: collectionName,
    documentId: documentId,
  );

  return document != null
      ? Response.ok(
          const JsonEncoder.withIndent('  ').convert(document),
          headers: {'content-type': 'application/json'},
        )
      : Response.notFound('document not found');
}

Future<Response> _setDocumentHandler(
  Request request,
  String collectionName,
  String documentId,
) async {
  if (collectionName.isEmpty) {
    return Response.badRequest(
        body: 'Can not read collectionName from the request');
  }

  if (documentId.isEmpty) {
    return Response.badRequest(
        body: 'Can not read documentId from the request');
  }

  final jsonData = await request.readAsString(Encoding.getByName('utf8'));

  final data = jsonDecode(jsonData);

  if (data is! Map) {
    return Response.badRequest(body: 'data must be a map');
  }

  await jsonFileStorage.internalSetDocument(
    collectionName: collectionName,
    documentId: documentId,
    documentData: data.cast<String, dynamic>(),
  );

  return Response.ok(
    const JsonEncoder.withIndent('  ').convert(data),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _createDocumentHandler(
  Request request,
  String collectionName,
) async {
  if (collectionName.isEmpty) {
    return Response.badRequest(
        body: 'Can not read collectionName from the request');
  }

  final jsonData = await request.readAsString(Encoding.getByName('utf8'));

  var data = jsonDecode(jsonData);

  if (data is! Map) {
    return Response.badRequest(body: 'data must be a map');
  }

  final documentData = data.cast<String, dynamic>();
  String? documentId;

  print(jsonEncode(documentData));

  if (data['id'] != null) {
    documentId = data['id'].toString();
    data.remove('id');
  }

  data = await jsonFileStorage.internalAddDocument(
    collectionName: collectionName,
    documentData: documentData,
    documentId: documentId,
  );

  return Response.ok(
    const JsonEncoder.withIndent('  ').convert(data),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _updateDocumentHandler(
  Request request,
  String collectionName,
  String documentId,
) async {
  if (collectionName.isEmpty) {
    return Response.badRequest(
        body: 'Can not read collectionName from the request');
  }

  if (documentId.isEmpty) {
    return Response.badRequest(
        body: 'Can not read documentId from the request');
  }

  final jsonData = await request.readAsString(Encoding.getByName('utf8'));

  final data = jsonDecode(jsonData);

  if (data is! Map) {
    return Response.badRequest(body: 'data must be a map');
  }

  await jsonFileStorage.internalUpdateDocument(
    collectionName: collectionName,
    documentId: documentId,
    documentData: data.cast<String, dynamic>(),
  );

  return Response.ok(
    const JsonEncoder.withIndent('  ').convert(data),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _deleteDocumentHandler(
  Request request,
  String collectionName,
  String documentId,
) async {
  if (collectionName.isEmpty) {
    return Response.badRequest(
        body: 'Can not read collectionName from the request');
  }

  if (documentId.isEmpty) {
    return Response.badRequest(
        body: 'Can not read documentId from the request');
  }

  await jsonFileStorage.internalDeleteDocument(
    collectionName: collectionName,
    documentId: documentId,
  );

  return Response.ok('Success');
}

Future<Response> _getQueryHandler(
  Request request,
  String collectionName,
) async {
  const queryMatcher = '?q=';
  final queryJsonEncoded = (request.requestedUri.toString().split(queryMatcher)
        ..removeAt(0))
      .join(queryMatcher);
  final queryJson = Uri.decodeComponent(queryJsonEncoded);
  final query = queryJson.trim().isEmpty ? {} : jsonDecode(queryJson);

  final docs =
      await jsonFileStorage.internalGetQuery(collectionName: collectionName);

  return Response.ok(
    const JsonEncoder.withIndent('  ').convert(docs),
    headers: {'content-type': 'application/json'},
  );
}

Future<Response> _replaceCollectionHandler(
  Request request,
  String collectionName,
) async {
  final jsonData = await request.readAsString(Encoding.getByName('utf8'));

  final data = jsonDecode(jsonData);

  if (data is! Map) {
    return Response.badRequest(
        body: 'Data must be a hash map where the documentId is map key.\n'
            'Example:\n'
            '{\n'
            '  "todo1_id": {\n'
            '    "name": "Todo 1",\n'
            '    "completed": false\n'
            '  }\n'
            '}');
  }

  await jsonFileStorage.internalReplaceCollection(
      collectionName: collectionName, data: data.cast());

  return Response.ok('Success');
}

Future<Response> _serviceRequestHandler(
  Request request,
  String serviceName,
) async {
  final jsonData = await request.readAsString(Encoding.getByName('utf8'));

  final data = jsonDecode(jsonData);

  switch (serviceName) {
    // case 'createManyTodos':
    //   if (data is! List) {
    //     return Response.badRequest(
    //         body: 'Data must be a hash map where the documentId is map key.\n'
    //             'Example:\n'
    //             '{\n'
    //             '  "todo1_id": {\n'
    //             '    "name": "Todo 1",\n'
    //             '    "completed": false\n'
    //             '  }\n'
    //             '}');
    //   } else {
    //     await jsonFileStorage.internalSetDocument(
    //         collectionName: 'todos', data: data.cast());
    //   }
    default:
      return Response.badRequest(
          body: 'This server does not support serviceRequest "$serviceName"');
  }
}
