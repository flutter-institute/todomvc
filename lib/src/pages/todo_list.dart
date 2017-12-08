// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of todomvc;

/// The filter values for which kind of filter tasks we will show
enum TypeFilter {
  ALL,
  ACTIVE,
  COMPLETED,
}


class TodoList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new TodoListState();
}


/// The bulk of the app's "smarts" are in this class
class TodoListState extends State<TodoList> {
  TypeFilter typeFilter;
  List<TodoItem> todos;

  @override
  void initState() {
    super.initState();
    typeFilter = TypeFilter.ALL;
    todos = [];
  }

  void setFilter(TypeFilter filter) {
    setState(() {
      this.typeFilter = filter;
    });
  }

  Widget buildToggleButton(TypeFilter type, String text) {
    final bool enabled = type == this.typeFilter;

    Widget button = new MaterialButton(
      key: new Key('filter-button-${text.toLowerCase()}'),
      textColor: enabled ? Colors.black : Colors.grey,
      child: new Text(text),
      onPressed: () => setFilter(type),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      minWidth: 0.0,
    );

    if (enabled) {
      button = new Container(
        decoration: new BoxDecoration(
          border: new Border.all(),
          borderRadius: new BorderRadius.circular(3.0),
        ),
        child: button,
      );
    }

    return button;
  }

  @override
  Widget build(BuildContext context) {
    // Apply our filter. If no filter just copy list, otherwise check the completed status
    // This is done at build time to simply our state and what we must keep track of
    final bool onlyActive = this.typeFilter == TypeFilter.ACTIVE;
    final List<TodoItem> visibleTodos = typeFilter == TypeFilter.ALL
        ? todos
        : todos.where((t) => t.completed != onlyActive).toList(growable: false);

    // Number of remaining tasks to complete
    final int remainingActive = todos
        .where((t) => !t.completed)
        .length;

    final bool allCompleted = todos.isNotEmpty && remainingActive == 0;

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('todos'),
      ),
      body: new Column(
        children: <Widget>[
          new TodoHeaderWidget(
            key: new Key('todo-header'),
            showToggleAll: todos.length > 0,
            toggleAllActive: allCompleted,
            onChangeToggleAll: () {
              this._toggleAll(!allCompleted);
            },
            onAddTodo: this._createTodo,
          ),
          new Expanded(
            flex: 2,
            child: new ListView.builder(
              key: new Key('todo-list'),
              itemCount: visibleTodos.length,
              itemBuilder: _buildTodoItem(visibleTodos),
            ),
          ),
        ],
      ),
      bottomNavigationBar: new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Stack(
          fit: StackFit.loose,
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            new Text('$remainingActive item${remainingActive == 1 ? '' : 's'} left'),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                buildToggleButton(TypeFilter.ALL, 'All'),
                buildToggleButton(TypeFilter.ACTIVE, 'Active'),
                buildToggleButton(TypeFilter.COMPLETED, 'Completed'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Method to create the widget builder for the todos that are passed in
  /// This allows us to have a separate function, to keep the code clean, while still allowing us to calculate the
  /// result of the filters are build-time.
  IndexedWidgetBuilder _buildTodoItem(List<TodoItem> todos) {
    return (BuildContext context, int idx) {
      final TodoItem todo = todos[idx];
      return new TodoWidget(
        key: new Key('todo-${todo.id}'),
        todo: todo,
        onToggle: (completed) {
          setState(() {
            todo.completed = completed;
          });
        },
        onTitleChanged: (newTitle) {
          this._editTodo(todo, newTitle);
        },
        onDelete: () {
          setState(() {
            this.todos.removeWhere((t) => t.id == todo.id);
          });
        },
      );
    };
  }

  void _toggleAll(bool toggled) {
    setState(() {
      todos.forEach((t) => t.completed = toggled);
    });
  }

  void _createTodo(String title) {
    setState(() {
      todos.add(new TodoItem(
        id: todos.length.toString(),
        title: title,
      ));
    });
  }

  void _editTodo(TodoItem todo, String newTitle) {
    setState(() {
      todo.title = newTitle;
    });
  }
}