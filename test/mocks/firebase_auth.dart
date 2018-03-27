// Copyright (c) 2018, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// @see https://github.com/flutter/plugins/blob/master/packages/firebase_auth/test/firebase_auth_test.dart

import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:channel_mock/channel_mock.dart';


class FirebaseAuthMock extends ChannelMock {
  FirebaseAuthMock()
      : super(FirebaseAuth.channel);

  Map<String, dynamic> setUp({
    mockIdToken = '12345',
    mockProviderId = 'firebase',
    mockUid = '12345',
    mockDisplayName = 'Auth Test User',
    mockPhotoUrl = 'http://www.example.com/',
    mockEmail = 'test@example.com',
  }) {
    super.reset();

    final Map<String, dynamic> mockUser = mockFirebaseUser(
      providerId: mockProviderId,
      uid: mockUid,
      displayName: mockDisplayName,
      photoUrl: mockPhotoUrl,
      email: mockEmail,
    );

    when('getIdToken').thenReturn(mockIdToken);

    when('startListeningAuthState').thenRespond(
      'onAuthStateChanged',
          (handle, _) =>
      <String, dynamic>{
        'id': handle,
        'user': mockUser,
      },
    );

    otherwise().thenReturn(mockUser);

    return mockUser;
  }

  Map<String, dynamic> mockFirebaseUser({
    @required String providerId,
    @required String uid,
    @required String displayName,
    @required String photoUrl,
    @required String email,
    bool isAnonymous = true,
    bool isEmailVerified = false,
  }) =>
      <String, dynamic>{
        'uid': uid,
        'isAnonymous': isAnonymous,
        'isEmailVerified': isEmailVerified,
        'providerData': <Map<String, String>>[
          <String, String>{
            'providerId': providerId,
            'uid': uid,
            'displayName': displayName,
            'photoUrl': photoUrl,
            'email': email,
          },
        ],
      };
}
