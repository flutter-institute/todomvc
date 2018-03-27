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

  /// List of Todos that are disabled in the UI while async operations are performed
  Set<String> disabledTodos;

  StreamSubscription<QuerySnapshot> todoSub;
  TodoStorage todoStorage;
  FirebaseUser user;

  @override
  void initState() {
    super.initState();
    typeFilter = TypeFilter.ALL;
    todos = [];
    disabledTodos = new Set();

    _auth.currentUser().then((FirebaseUser user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        todoStorage = new TodoStorage.forUser(user: user);
        todoSub?.cancel();
        todoSub = todoStorage.list().listen((QuerySnapshot snapshot) {
          final List<TodoItem> todos = snapshot.documents.map(TodoStorage.fromDocument).toList(growable: false);
          setState(() {
            this.todos = todos;
          });
        });

        setState(() {
          this.user = user;
        });
      }
    });
  }

  @override
  void dispose() {
    todoSub?.cancel();
    super.dispose();
  }

  void setFilter(TypeFilter filter) {
    setState(() {
      typeFilter = filter;
    });
  }

  Widget buildToggleButton(TypeFilter type, String text) {
    final bool enabled = type == typeFilter;

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

  Widget buildContent(int remainingActive) {
    if (user == null) {
      return new LoadingIndicator();
    } else {
      // Apply our filter. If no filter just copy list, otherwise check the completed status
      // This is done at build time to simply our state and what we must keep track of
      final bool onlyActive = typeFilter == TypeFilter.ACTIVE;
      final List<TodoItem> visibleTodos =
          typeFilter == TypeFilter.ALL ? todos : todos.where((t) => t.completed != onlyActive).toList(growable: false);

      final bool allCompleted = todos.isNotEmpty && remainingActive == 0;

      return new Column(
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
              key: const Key('todo-list'),
              itemCount: visibleTodos.length,
              itemBuilder: _buildTodoItem(visibleTodos),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Number of remaining tasks to complete
    final int remainingActive = todos.where((t) => !t.completed).length;

    final ThemeData themeData = Theme.of(context);

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Todos'),
      ),
      drawer: new Drawer(
        child: new ListView(
          primary: false,
          children: <Widget>[
            new DrawerHeader(
              child: new Center(
                child: new Text(
                  "Todo MVC",
                  style: themeData.textTheme.title,
                ),
              ),
            ),
            new ListTile(
              title: const Text('Logout', textAlign: TextAlign.right),
              trailing: const Icon(Icons.exit_to_app),
              onTap: () async {
                await signOutWithGoogle();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
      ),
      body: buildContent(remainingActive),
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
        disabled: disabledTodos.contains(todo.id),
        onToggle: (completed) {
          this._toggleTodo(todo, completed);
        },
        onTitleChanged: (newTitle) {
          this._editTodo(todo, newTitle);
        },
        onDelete: () {
          this._deleteTodo(todo);
        },
      );
    };
  }

  void _disableTodo(TodoItem todo) {
    setState(() {
      disabledTodos.add(todo.id);
    });
  }

  void _enabledTodo(TodoItem todo) {
    setState(() {
      disabledTodos.remove(todo.id);
    });
  }

  void _toggleAll(bool toggled) {
    todos.forEach((t) => this._toggleTodo(t, toggled));
  }

  void _createTodo(String title) {
    todoStorage.create(title);
  }

  void _deleteTodo(TodoItem todo) {
    this._disableTodo(todo);
    todoStorage.delete(todo.id).catchError((_) {
      this._enabledTodo(todo);
    });
  }

  void _toggleTodo(TodoItem todo, bool completed) {
    this._disableTodo(todo);
    todo.completed = completed;
    todoStorage.update(todo).whenComplete(() {
      this._enabledTodo(todo);
    });
  }

  void _editTodo(TodoItem todo, String newTitle) {
    this._disableTodo(todo);
    todo.title = newTitle;
    todoStorage.update(todo).whenComplete(() {
      this._enabledTodo(todo);
    });
  }
}
