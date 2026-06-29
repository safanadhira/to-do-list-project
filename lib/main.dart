import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedThemeMode = prefs.getString(_themeModeKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = storedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleThemeMode() async {
    final ThemeMode nextThemeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeModeKey,
      nextThemeMode == ThemeMode.dark ? 'dark' : 'light',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = nextThemeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Home(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleThemeMode,
      ),
    );
  }
}

enum TaskFilter { all, completed, incomplete }

class TaskItem {
  final String title;
  final String description;
  bool isCompleted;

  TaskItem({
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  TaskItem copyWith({
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return TaskItem(
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Convert TaskItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  // Create TaskItem from JSON
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class Home extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const Home({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TaskFilter _currentFilter = TaskFilter.all;
  late SharedPreferences prefs;
  final List<TaskItem> _tasks = [
    TaskItem(
      title: "Task 1",
      description: "Complete project documentation",
      isCompleted: false,
    ),
    TaskItem(
      title: "Task 2",
      description: "Review code changes",
      isCompleted: true,
    ),
    TaskItem(
      title: "Task 3",
      description: "Update task management app",
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    prefs = await SharedPreferences.getInstance();
    await _loadTasks();
  }

  Future<void> _saveTasks() async {
    final List<String> taskJsonList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', taskJsonList);
  }

  Future<void> _loadTasks() async {
    final List<String>? taskJsonList = prefs.getStringList('tasks');
    if (taskJsonList != null && taskJsonList.isNotEmpty) {
      setState(() {
        _tasks.clear();
        _tasks.addAll(
          taskJsonList.map((taskJson) => TaskItem.fromJson(jsonDecode(taskJson))).toList(),
        );
      });
    }
  }

  List<TaskItem> get _filteredTasks {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.incomplete:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  void _toggleFilter() {
    setState(() {
      _currentFilter = TaskFilter.values[(_currentFilter.index + 1) % TaskFilter.values.length];
    });
  }

  void _updateTaskCompletion(int index, bool isCompleted) {
    setState(() {
      _tasks[index].isCompleted = isCompleted;
    });
    _saveTasks();
  }

  Future<void> _editTask(int index) async {
    if (index < 0 || index >= _tasks.length) {
      return;
    }

    final task = _tasks[index];
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);

    final TaskItem? updatedTask = await showDialog<TaskItem>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task description',
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  task.copyWith(
                    title: title,
                    description: description.isEmpty ? 'No description provided' : description,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updatedTask == null) {
      return;
    }

    setState(() {
      _tasks[index] = updatedTask;
    });
    _saveTasks();
  }

  Future<void> _deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('This will remove the task and its details. Continue?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  Future<void> _addNewTask() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final TaskItem? newTask = await showDialog<TaskItem>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task description',
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  TaskItem(
                    title: title,
                    description: description.isEmpty ? 'No description provided' : description,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newTask == null) {
      return;
    }

    setState(() {
      _tasks.add(newTask);
    });
    _saveTasks();
  }

  String get _filterLabel {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return "Completed";
      case TaskFilter.incomplete:
        return "Incomplete";
      case TaskFilter.all:
        return "All";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Safa's To-Do List",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: widget.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Title Section at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40.0,
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      "Today's Tasks",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _toggleFilter,
                  icon: const Icon(Icons.filter_list),
                  label: Text("Filter: $_filterLabel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Task Cards Section
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                final task = _filteredTasks[index];
                final originalIndex = _tasks.indexOf(task);
                return TaskCard(
                  task: task,
                  onCompletionChanged: (value) {
                    if (originalIndex != -1) {
                      _updateTaskCompletion(originalIndex, value);
                    }
                  },
                  onEdit: () {
                    if (originalIndex != -1) {
                      _editTask(originalIndex);
                    }
                  },
                  onDelete: () {
                    if (originalIndex != -1) {
                      _deleteTask(originalIndex);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: _addNewTask,
        icon: const Icon(Icons.add),
        label: const Text("Add New Task"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool> onCompletionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onCompletionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isCompleted ? Colors.green : Colors.grey,
                size: 28.0,
              ),
              onPressed: () {
                onCompletionChanged(!task.isCompleted);
              },
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.brown,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}