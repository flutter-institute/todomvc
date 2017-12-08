// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library todomvc;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'pages/todo_list.dart';
part 'models/todo_item.dart';
part 'widgets/todo_header.dart';
part 'widgets/todo_widget.dart';

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter • TodoMVC',
      theme: new ThemeData(
        fontFamily: 'Helvetica Neue',
        primarySwatch: Colors.blueGrey,
      ),
      home: new TodoList(),
    );
  }
}
