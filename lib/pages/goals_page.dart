import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import 'package:pw_24/services/auth_service.dart';
import 'package:pw_24/services/navigation_service.dart';
import '../services/chatgpt_service.dart'; // Add this import

const List<String> list = <String>[
  'Education',
  'Fitness',
  'Spiritual',
  'Financial',
  'Social'
];

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  String dropdownValue = list.first;
  final TextEditingController _textEditingController = TextEditingController();
  final ChatGPTService _chatGPTService = ChatGPTService();
  final TextEditingController _goalInputController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final NavigationService _navigationService = NavigationService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _GoalTypeSelector(),
          ),
        ),
        ElevatedButton(
          onPressed: _displayGoalInputDialog,
          child: const Text('Generate Goal Plan'),
        ),
        Expanded(child: _messagesListView()),
      ],
    );
  }

  Widget _messagesListView() {
    return StreamBuilder(
      stream: _databaseService.getTodos(),
      builder: (context, snapshot) {
        List todos = snapshot.data?.docs ?? [];
        if (todos.isEmpty) {
          return const Center(
            child: Text("Add a task!"),
          );
        }
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            Todo todo = todos[index].data();
            String todoId = todos[index].id;
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(todo.task),
                  subtitle: Text(
                    DateFormat("dd-MM-yyyy h:mm a").format(
                      todo.updatedOn.toDate(),
                    ),
                  ),
                  trailing: Checkbox(
                    value: todo.isDone,
                    onChanged: (value) {
                      Todo updatedTodo = todo.copyWith(
                          isDone: !todo.isDone, updatedOn: Timestamp.now());
                      _databaseService.updateTodo(todoId, updatedTodo);
                    },
                  ),
                  onLongPress: () {
                    _databaseService.deleteTodo(todoId);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _GoalTypeSelector() {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            dropdownValue = value;
          });
          _databaseService.updateGoalType(_authService.user!.uid, value);
        }
      },
      items: list.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  void _displayTextInputDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a task'),
          content: TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(hintText: "Task...."),
          ),
          actions: <Widget>[
            MaterialButton(
              color: Theme.of(context).colorScheme.primary,
              textColor: Colors.white,
              child: const Text('Ok'),
              onPressed: () {
                Todo todo = Todo(
                    task: _textEditingController.text,
                    isDone: false,
                    createdOn: Timestamp.now(),
                    updatedOn: Timestamp.now(),
                    uid: _authService.user!.uid);
                _databaseService.addTodo(todo);
                Navigator.pop(context);
                _textEditingController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void _displayGoalInputDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter your goal'),
          content: TextField(
            controller: _goalInputController,
            decoration: const InputDecoration(hintText: "Your goal..."),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
                _goalInputController.clear();
              },
            ),
            TextButton(
              child: const Text('Generate Plan'),
              onPressed: () {
                Navigator.pop(context);
                _generateActionPlan(_goalInputController.text);
                _goalInputController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  void _generateActionPlan(String goal) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final prompt =
          "Generate a concise 5-step action plan for the following goal: $goal. Format each step as a separate task.";
      final response = await _chatGPTService.generateResponse(prompt);

      // Parse the response and add tasks
      final tasks = response.split('\n');
      for (var task in tasks) {
        if (task.isNotEmpty) {
          Todo todo = Todo(
            task:
                task.replaceFirst(RegExp(r'^\d+\.\s*'), ''), // Remove numbering
            isDone: false,
            createdOn: Timestamp.now(),
            updatedOn: Timestamp.now(),
            uid: _authService.user!.uid,
          );
          _databaseService.addTodo(todo);
        }
      }

      // Close loading indicator
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Action plan generated and added to your tasks!')),
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);

      // Show detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating action plan: ${e.toString()}'),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'DISMISS',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Log the error for debugging
      print('Error generating action plan: $e');
    }
  }
}