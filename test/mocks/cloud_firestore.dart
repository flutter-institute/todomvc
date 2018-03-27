// Copyright (c) 2018, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// @see https://github.com/flutter/plugins/blob/master/packages/cloud_firestore/test/cloud_firestore_test.dart

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:channel_mock/channel_mock.dart';


class CloudFirestoreMock extends ChannelMock {
  List<int> _listenerHandles;

  CloudFirestoreMock()
      : super(Firestore.channel);

  Map<String, dynamic> _makeQuerySnapshot(int handle, Map<String, dynamic> data) {
    final List<dynamic> documents = data.values.toList();
    return <String, dynamic>{
      'handle': handle,
      'paths': data.keys.toList(),
      'documents': documents,
      'documentChanges': documents.map((d) =>
      <String, dynamic>{
        'oldIndex': -1,
        'newIndex': 0,
        'type': 'DocumentChangeType.added',
        'document': d,
      }).toList(),
    };
  }

  Future _notifySnapshotListeners(Map<String, dynamic> data) async {
    if (data?.isNotEmpty == true) {
      List<Future> messages = _listenerHandles.map((handle) =>
          BinaryMessages.handlePlatformMessage(
              Firestore.channel.name,
              Firestore.channel.codec.encodeMethodCall(
                new MethodCall('QuerySnapshot', _makeQuerySnapshot(handle, data)),
              ),
                  (_) {}))
          .toList();

      await Future.wait(messages);
    }
  }

  void setUp(Map<String, dynamic> mockDocumentSnapshotData) {
    super.reset();

    _listenerHandles = [];

    when('Query#addSnapshotListener').thenCall((handle, _) {
      _listenerHandles.add(handle);
      _notifySnapshotListeners(mockDocumentSnapshotData);
      return handle;
    });

    when('Query#removeListener').thenCall((_, arguments) {
      int toRemove = arguments['handle'];
      if (toRemove != null) {
        _listenerHandles.remove(toRemove);
      }
    });

    when('Firestore#runTransaction').thenCall((handle, arguments) async {
      dynamic _transactionResult;

      // Run the transaction
      await BinaryMessages.handlePlatformMessage(
        Firestore.channel.name,
        Firestore.channel.codec.encodeMethodCall(
          new MethodCall('DoTransaction', arguments),
        ),
            (a) {
          _transactionResult = Firestore.channel.codec.decodeEnvelope(a);
        },
      );

      // Notify listeners of new documents
      await _notifySnapshotListeners(mockDocumentSnapshotData);

      return _transactionResult;
    });

    when('Transaction#get').thenCall((_, arguments) {
      final String path = arguments['path'];
      return <String, dynamic>{
        'path': path,
        'data': mockDocumentSnapshotData[path],
      };
    });

    when('Transaction#set').thenCall((_, arguments) {
      final String path = arguments['path'];
      mockDocumentSnapshotData[path] = arguments['data'];
    });

    when('Transaction#update').thenCall((_, arguments) {
      final String path = arguments['path'];
      (mockDocumentSnapshotData[path] as Map).addAll(arguments['data']);
    });

    when('Transaction#delete').thenCall((_, arguments) {
      final String path = arguments['path'];
      mockDocumentSnapshotData.remove(path);
    });
  }
}