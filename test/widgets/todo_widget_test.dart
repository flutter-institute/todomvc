// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todomvc/src/todo_app.dart';

void main() {
  testWidgets('Marks as completed', (WidgetTester tester) async {
    final TodoItem todo = new TodoItem(id: 'id', title: 'test');
    bool value;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoWidget(
          todo: todo,
          onToggle: (v) {
            value = v;
          },
        ),
      ),
    ));
    expect(value, isNull);

    final Checkbox box = tester.widget(find.byType(Checkbox));
    expect(box.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    expect(value, isTrue);
  });

  testWidgets('Marks as active', (WidgetTester tester) async {
    final TodoItem todo = new TodoItem(id: 'id', title: 'test', completed: true);
    bool value;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoWidget(
          todo: todo,
          onToggle: (v) {
            value = v;
          },
        ),
      ),
    ));
    expect(value, isNull);

    final Checkbox box = tester.widget(find.byType(Checkbox));
    expect(box.value, isTrue);

    await tester.tap(find.byType(Checkbox));
    expect(value, isFalse);
  });

  testWidgets('Deletes', (WidgetTester tester) async {
    final TodoItem todo = new TodoItem(id: 'id', title: 'test', completed: true);
    bool called;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoWidget(
          todo: todo,
          onDelete: () {
            called = true;
          },
        ),
      ),
    ));
    expect(called, isNull);

    await tester.tap(find.byType(IconButton));
    expect(called, isTrue);
  });

  testWidgets('Creates the edit box and edits', (WidgetTester tester) async {
    final TodoItem todo = new TodoItem(id: 'id', title: 'test', completed: true);
    String value;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new TodoWidget(
          todo: todo,
          onTitleChanged: (newTitle) {
            value = newTitle;
          },
        ),
      ),
    ));
    expect(value, isNull);

    Text titleText = tester.widget(find.byType(Text));
    expect(titleText.data, 'test');

    await tester.longPress(find.byType(Text));

    // Make sure the value is correct
    TextField editBox = tester.widget(find.byType(TextField));
    expect(editBox.controller.text, 'test');

    // Test that we attempt to update the value
    editBox.onSubmitted('new-value');
    expect(value, 'new-value');
  });
}
