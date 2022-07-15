// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stater/custom/rest_storage.dart';

void main() {
  Process? process;

  setUp(() async {
    process = await Process.start(
      'dart',
      ['./example_server/server.dart'],
      runInShell: true,
    );

    stdout.addStream(process!.stdout);
    stderr.addStream(process!.stderr);

    print('http server running. process id = ${process?.pid}');

    return Future.delayed(const Duration(milliseconds: 1000));
  });

  tearDown(() {
    print('process pid = ${process?.pid}');
    process?.kill();
  });

  test(
      'make sure RestStorage does not allow a read operation '
      'to start until a write operation is completed', () async {
    /// without this line, there is a socket exception that I can not explain :(
    await Future.delayed(const Duration(milliseconds: 1000));

    final restAdapter = RestAdapter(endpoint: 'http://0.0.0.0:54123/api');

    await restAdapter.addDocument<String, dynamic>(
        collectionName: 'todos',
        documentId: '1',
        documentData: {'name': 'Todo 1'});

    final writeFuture = restAdapter.addDocument<String, dynamic>(
        collectionName: 'todos',
        documentId: '2',
        documentData: {'name': 'Todo 2'});

    final readFuture =
        restAdapter.getDocument(collectionName: 'todos', documentId: '1');

    await writeFuture;

    await readFuture;

    final fasterResponse = await Future.any([writeFuture, readFuture]);

    expect(fasterResponse.id, '2');

    final bothResponses = await Future.wait([writeFuture, readFuture]);

    expect(bothResponses[0].id, '2');

    expect(bothResponses[1].id, '1');
  });
}
