// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todomvc/src/todo_app.dart';

void main() {
  Future<Null> createSUT(WidgetTester tester, {List<TodoItem> todos, TypeFilter filter}) async {
    await tester.pumpWidget(
        new MaterialApp(
          home: new Material(
            child: new TodoList(),
          ),
        ));

    // Flags for our change requirements
    final bool setTodos = todos != null && todos.isNotEmpty;
    final bool setFilter = filter != null;

    if (setTodos || setFilter) {
      final TodoListState listState = tester.state<TodoListState>(find.byType(TodoList));
      listState.setState(() {
        if (setTodos) {
          listState.todos = todos;
        }
        if (setFilter) {
          listState.typeFilter = filter;
        }
      });

      await tester.pump();
    }
  }

  testWidgets('Renders an empty page on first load', (WidgetTester tester) async {
    await createSUT(tester);
    expect(find.byKey(new Key('todo-list')), findsOneWidget);
    expect(find.byType(TodoWidget), findsNothing);
  });

  testWidgets('Renders correct number of todos with default filter', (WidgetTester tester) async {
    await createSUT(tester, todos: <TodoItem>[
      new TodoItem(id: 'first', title: 'First Todo - Active'),
      new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
      new TodoItem(id: 'third', title: 'Third Todo - Active'),
    ]);
    expect(find.byKey(new Key('todo-list')), findsOneWidget);
    expect(find.byType(TodoWidget), findsNWidgets(3));
  });

  testWidgets('Properly applies the filters', (WidgetTester tester) async {
    await createSUT(tester, todos: <TodoItem>[
      new TodoItem(id: 'first', title: 'First Todo - Active'),
      new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
      new TodoItem(id: 'third', title: 'Third Todo - Active'),
    ]);

    // Click the active filter
    await tester.tap(find.byKey(new Key('filter-button-active')));
    await tester.pump();

    final Finder activeTodos = find.byType(TodoWidget);
    expect(activeTodos, findsNWidgets(2));
    TodoWidget visibleWidget = tester.widget(activeTodos.at(0));
    expect(visibleWidget.todo.id, 'first');
    visibleWidget = tester.widget(activeTodos.at(1));
    expect(visibleWidget.todo.id, 'third');

    // Click the completed filter
    await tester.tap(find.byKey(new Key('filter-button-completed')));
    await tester.pump();

    final Finder completedTodos = find.byType(TodoWidget);
    expect(completedTodos, findsOneWidget);
    visibleWidget = tester.widget(activeTodos.at(0));
    expect(visibleWidget.todo.id, 'second');

    // Click the all filter
    await tester.tap(find.byKey(new Key('filter-button-all')));
    await tester.pump();

    expect(find.byType(TodoWidget), findsNWidgets(3));
  });

  testWidgets('toggles a single todo', (WidgetTester tester) async {
    await createSUT(tester, todos: <TodoItem>[
      new TodoItem(id: 'first', title: 'First Todo - Active'),
      new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
      new TodoItem(id: 'third', title: 'Third Todo - Active'),
    ]);

    // Verify initial state
    TodoWidget firstTodo = tester.widget(find.byType(TodoWidget).first);
    expect(firstTodo.todo.completed, isFalse);

    // Toggle an item to completed
    await tester.tap(find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(Checkbox),
    ));
    await tester.pump();

    // Verify it switched
    firstTodo = tester.widget(find.byType(TodoWidget).first);
    expect(firstTodo.todo.completed, isTrue);

    // Toggle back
    await tester.tap(find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(Checkbox),
    ));
    await tester.pump();

    // Verify it switched
    firstTodo = tester.widget(find.byType(TodoWidget).first);
    expect(firstTodo.todo.completed, isFalse);
  });

  testWidgets('toggles a widget properly out of the filtered group', (WidgetTester tester) async {
    await createSUT(tester,
      todos: <TodoItem>[
        new TodoItem(id: 'first', title: 'First Todo - Active'),
        new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
        new TodoItem(id: 'third', title: 'Third Todo - Active'),
      ],
      filter: TypeFilter.ACTIVE,
    );

    final Finder todos = find.byType(TodoWidget);
    expect(todos, findsNWidgets(2));

    // Toggle an item to completed
    await tester.tap(find.descendant(
      of: todos.first,
      matching: find.byType(Checkbox),
    ));
    await tester.pump();

    // Verify the widget no longer shows up
    expect(find.byType(TodoWidget), findsOneWidget);
  });

  testWidgets('toggles all todos back and forth', (WidgetTester tester) async {
    await createSUT(tester,
      todos: <TodoItem>[
        new TodoItem(id: 'first', title: 'First Todo - Active'),
        new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
        new TodoItem(id: 'third', title: 'Third Todo - Active'),
      ],
      filter: TypeFilter.ACTIVE,
    );

    // Only the currently active are visible
    Finder todos = find.byType(TodoWidget);
    expect(todos, findsNWidgets(2));

    final Finder toggleAll = find.descendant(
      of: find.byType(TodoHeaderWidget),
      matching: find.byType(IconButton),
    );

    // Tap the toggle all button
    await tester.tap(toggleAll);
    await tester.pump();

    // Everything is hidden
    todos = find.byType(TodoWidget);
    expect(todos, findsNothing);

    // Tap the toggle all button again
    await tester.tap(toggleAll);
    await tester.pump();

    // All are visible
    todos = find.byType(TodoWidget);
    expect(todos, findsNWidgets(3));
  });

  testWidgets('creates a new todo at the bottom of the list', (WidgetTester tester) async {
    await createSUT(tester,
      todos: <TodoItem>[
        new TodoItem(id: 'first', title: 'First Todo - Active'),
        new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
        new TodoItem(id: 'third', title: 'Third Todo - Active'),
      ],
    );

    // Enter in the text and submit it
    final Finder headerInput = find.descendant(
      of: find.byType(TodoHeaderWidget),
      matching: find.byType(TextField),
    );
    await tester.enterText(headerInput, "New Todo");
    TextField f = tester.widget(headerInput);
    f.onSubmitted(f.controller.value.text);
    await tester.pump();

    final Finder todos = find.byType(TodoWidget);
    expect(todos, findsNWidgets(4));
    final TodoWidget newWidget = tester.widget(todos.last);
    expect(newWidget.todo.title, 'New Todo');
    expect(newWidget.todo.completed, isFalse);
  });

  testWidgets('edits a todo', (WidgetTester tester) async {
    await createSUT(tester,
      todos: <TodoItem>[
        new TodoItem(id: 'first', title: 'First Todo - Active'),
        new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
        new TodoItem(id: 'third', title: 'Third Todo - Active'),
      ],
    );

    // Find the first text box
    final Finder firstTodo = find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(Text),
    );
    expect(firstTodo, findsOneWidget);

    // Long press to enter edit mode
    await tester.longPress(firstTodo);
    await tester.pump();

    // Find the edit box
    final Finder editTodo = find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(TextField),
    );
    expect(editTodo, findsOneWidget);

    // Make our edits
    await tester.enterText(editTodo, 'New Title');
    final TextField editBox = tester.widget(editTodo);
    expect(editBox.controller.text, 'New Title');
    editBox.onSubmitted(editBox.controller.text);
    await tester.pump();

    // Verify result
    final Finder result = find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(Text),
    );
    expect(result, findsOneWidget);

    final TodoWidget widget = tester.widget(find.byType(TodoWidget).first);
    expect(widget.todo.title, 'New Title');
  });

  testWidgets('deletes a todo', (WidgetTester tester) async {
    await createSUT(tester,
      todos: <TodoItem>[
        new TodoItem(id: 'first', title: 'First Todo - Active'),
        new TodoItem(id: 'second', title: 'Second Todo - Completed', completed: true),
        new TodoItem(id: 'third', title: 'Third Todo - Active'),
      ],
    );

    // Delete the first item
    await tester.tap(find.descendant(
      of: find.byType(TodoWidget).first,
      matching: find.byType(IconButton),
    ));
    await tester.pump();

    // Verify result
    final Finder todos = find.byType(TodoWidget);
    expect(todos, findsNWidgets(2));

    TodoWidget widget = tester.widget(todos.first);
    expect(widget.todo.id, 'second');
    widget = tester.widget(todos.last);
    expect(widget.todo.id, 'third');
  });
}