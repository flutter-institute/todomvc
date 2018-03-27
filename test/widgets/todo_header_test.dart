// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todomvc/src/todo_app.dart';

void main() {
  testWidgets('Header adds todo', (WidgetTester tester) async {
    Key inputKey = new UniqueKey();
    String value;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoHeaderWidget(
          textInputKey: inputKey,
          onAddTodo: (title) {
            value = title;
          },
        ),
      ),
    ));
    expect(value, isNull);

    await tester.enterText(find.byKey(inputKey), "test-todo\n");
    TextField f = tester.widget(find.byKey(inputKey));
    f.onSubmitted(f.controller.value.text);
    expect(value, equals("test-todo"));

    // No toggle all button
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('Shows the toggle button', (WidgetTester tester) async {
    bool called = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoHeaderWidget(
          showToggleAll: true,
          onChangeToggleAll: () {
            called = true;
          },
          onAddTodo: (title) {},
        ),
      ),
    ));
    expect(called, isFalse);

    await tester.tap(find.byType(IconButton));

    expect(called, isTrue);
  });
}
