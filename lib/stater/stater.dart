library stater;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:flutter/material.dart';

import 'adapter.dart';
import 'collection_reference.dart';

@immutable
class StateMachine {
  const StateMachine(Adapter adapter) : _adapter = adapter;

  final Adapter _adapter;

  Adapter get adapter => _adapter;

  CollectionReference collection(String collectionPath) {
    // return _adapter.collection(collectionPath);
    throw 'not implemented';
  }
}

final a = FirebaseFirestore.instance.collection('chatters').doc('bla').get();

// final restAdapter = RestAdapter('http://100.81.80.104:6868/api');
// final localStorageAdapter = LocalStorageAdapter('DB');

// class StateManager {
//   static get preferences => localStorageAdapter.collection('preferences');
//   static get users =>
//       restAdapter.collection('users').withConverter(fromDB, toDB);
// }