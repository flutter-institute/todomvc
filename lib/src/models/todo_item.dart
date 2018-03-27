// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of todomvc;

/// A simple model for holding information about each of our items
class TodoItem {
  final String id;
  String title;
  bool completed;

  TodoItem({
    @required this.id,
    @required this.title,
    this.completed = false,
  })  : assert(id != null && id.isNotEmpty),
        assert(title != null && title.isNotEmpty),
        assert(completed != null);

  TodoItem.fromMap(Map<String, dynamic> data)
      : this(id: data['id'], title: data['title'], completed: data['completed'] ?? false);

  Map<String, dynamic> toMap() => {
        'id': this.id,
        'title': this.title,
        'completed': this.completed,
      };
}
