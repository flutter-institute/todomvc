// Copyright (c) 2017, Brian Armstrong. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of todomvc;

/// The header widget for our main list page
class TodoHeaderWidget extends StatelessWidget {
  final TextEditingController _newTitleController = new TextEditingController();

  /// The key to locate the internal text input
  final Key textInputKey;

  /// Whether we should show the toggle all icon button
  final bool showToggleAll;

  /// Whether the toggle all should be enabled
  final bool toggleAllActive;

  /// Callback for when toggle all is clicked
  final VoidCallback onChangeToggleAll;

  /// Callback for when a new task should be created
  final ValueSetter<String> onAddTodo;

  TodoHeaderWidget({
    Key key,
    this.textInputKey,
    this.showToggleAll = false,
    this.toggleAllActive = false,
    this.onChangeToggleAll,
    @required this.onAddTodo,
  })  : assert(onAddTodo != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    // Only add the "Toggle All" icon if `showToggleAll` is true and we have a callback for it
    if (this.showToggleAll && this.onChangeToggleAll != null) {
      children.add(new IconButton(
        icon: new Icon(
          Icons.arrow_downward,
          color: this.toggleAllActive ? Colors.black : Colors.grey,
        ),
        alignment: Alignment.bottomCenter,
        onPressed: this.onChangeToggleAll,
      ));
    }

    // Always add the input box
    children.add(new Expanded(
      flex: 2,
      child: new TextField(
        key: textInputKey,
        controller: _newTitleController,
        decoration: new InputDecoration(hintText: 'What needs to be done?'),
        onSubmitted: (String value) {
          // Notify that we're adding a new item, and clear the text field
          this.onAddTodo(value);
          _newTitleController.text = "";
        },
      ),
    ));

    return new Padding(
      // If we have the toggle all box, left the icon be our left padding
      padding: new EdgeInsets.fromLTRB(this.showToggleAll ? 0.0 : 10.0, 10.0, 10.0, 10.0),
      child: new Row(children: children),
    );
  }
}
