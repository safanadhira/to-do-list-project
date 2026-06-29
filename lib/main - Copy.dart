import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
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
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TaskFilter _currentFilter = TaskFilter.all;
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

  List<TaskItem> get _filteredTasks {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.incomplete:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.all:
      default:
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
  }

  String get _filterLabel {
    switch (_currentFilter) {
      case TaskFilter.completed:
        return "Completed";
      case TaskFilter.incomplete:
        return "Incomplete";
      case TaskFilter.all:
      default:
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
        backgroundColor: Colors.brown[500],
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
                      color: Colors.brown,
                      size: 40.0,
                    ),
                    const SizedBox(width: 10.0),
                    const Text(
                      "Today's Tasks",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
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
                    backgroundColor: Colors.brown[500],
                    foregroundColor: Colors.white,
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
          backgroundColor: Colors.brown[500],
          foregroundColor: Colors.white,
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
                      color: Colors.brown,
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
                      color: Colors.brown[700],
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