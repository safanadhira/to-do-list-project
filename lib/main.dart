import 'dart:async';
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

const String _defaultCategory = 'General';

class TaskItem {
  final String title;
  final String description;
  bool isCompleted;
  final DateTime? deadline;
  final String category;

  TaskItem({
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.deadline,
    this.category = _defaultCategory,
  });

  TaskItem copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? deadline,
    String? category,
  }) {
    return TaskItem(
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
    );
  }

  // Convert TaskItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'category': category,
    };
  }

  // Create TaskItem from JSON
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'] as String) : null,
      category: json['category'] as String? ?? _defaultCategory,
    );
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _formatCountdown(Duration duration) {
  final int days = duration.inDays;
  final int hours = duration.inHours.remainder(24);
  final int minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return '${days}d ${hours}h';
  }

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  if (minutes > 0) {
    return '${minutes}m';
  }

  return 'less than 1m';
}

String getDeadlineCountdownText(DateTime deadline) {
  final Duration difference = deadline.difference(DateTime.now());

  if (difference.isNegative) {
    return 'Overdue by ${_formatCountdown(difference.abs())}';
  }

  return 'Due in ${_formatCountdown(difference)}';
}

String _formatDeadlineLabel(BuildContext context, DateTime deadline) {
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  final String dateText = localizations.formatFullDate(deadline);
  final String timeText = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(deadline));
  return '$dateText at $timeText';
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
  String? _currentCategoryFilter;
  Timer? _countdownTimer;
  late SharedPreferences prefs;
  List<String> _categories = <String>[_defaultCategory];
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
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initStorage() async {
    prefs = await SharedPreferences.getInstance();
    await _loadTasks();
    await _loadCategories();
  }

  Future<void> _saveTasks() async {
    final List<String> taskJsonList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', taskJsonList);
  }

  Future<void> _saveCategories() async {
    await prefs.setStringList('categories', _categories);
  }

  List<String> _buildCategoryList(Iterable<String> categories) {
    final Set<String> seen = <String>{};
    final List<String> orderedCategories = <String>[];

    void addCategory(String category) {
      final String normalized = category.trim();
      if (normalized.isEmpty || seen.contains(normalized)) {
        return;
      }

      seen.add(normalized);
      orderedCategories.add(normalized);
    }

    addCategory(_defaultCategory);
    for (final String category in categories) {
      addCategory(category);
    }

    return orderedCategories;
  }

  Future<void> _loadCategories() async {
    final List<String>? storedCategories = prefs.getStringList('categories');
    final List<String> taskCategories = _tasks.map((task) => task.category).toList();
    final List<String> mergedCategories = _buildCategoryList([
      ...?storedCategories,
      ...taskCategories,
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = mergedCategories;
    });

    await _saveCategories();
  }

  Future<void> _addCategory(String category) async {
    final String trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty) {
      return;
    }

    setState(() {
      _categories = _buildCategoryList([
        ..._categories,
        trimmedCategory,
      ]);
    });

    await _saveCategories();
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
    return _tasks.where((task) {
      final bool matchesStatus = switch (_currentFilter) {
        TaskFilter.completed => task.isCompleted,
        TaskFilter.incomplete => !task.isCompleted,
        TaskFilter.all => true,
      };

      final bool matchesCategory =
          _currentCategoryFilter == null || task.category == _currentCategoryFilter;

      return matchesStatus && matchesCategory;
    }).toList();
  }

  void _toggleFilter() {
    setState(() {
      _currentFilter = TaskFilter.values[(_currentFilter.index + 1) % TaskFilter.values.length];
    });
  }

  bool _matchesCurrentFilter(TaskItem task) {
    final bool matchesStatus = switch (_currentFilter) {
      TaskFilter.completed => task.isCompleted,
      TaskFilter.incomplete => !task.isCompleted,
      TaskFilter.all => true,
    };

    final bool matchesCategory =
        _currentCategoryFilter == null || task.category == _currentCategoryFilter;

    return matchesStatus && matchesCategory;
  }

  void _toggleCategoryFilter(String? category) {
    setState(() {
      _currentCategoryFilter = category;
    });
  }

  void _reorderVisibleTasks(int oldIndex, int newIndex) {
    final List<TaskItem> visibleTasks = _filteredTasks;
    final List<TaskItem> reorderedVisibleTasks = List<TaskItem>.from(visibleTasks);

    final TaskItem movedTask = reorderedVisibleTasks.removeAt(oldIndex);
    reorderedVisibleTasks.insert(newIndex, movedTask);

    setState(() {
      int visibleIndex = 0;

      for (int taskIndex = 0; taskIndex < _tasks.length; taskIndex++) {
        if (_matchesCurrentFilter(_tasks[taskIndex])) {
          _tasks[taskIndex] = reorderedVisibleTasks[visibleIndex];
          visibleIndex += 1;
        }
      }
    });
    _saveTasks();
  }

  void _updateTaskCompletion(int index, bool isCompleted) {
    setState(() {
      _tasks[index].isCompleted = isCompleted;
    });
    _saveTasks();
  }

  Future<TaskItem?> _showTaskDialog({
    required String dialogTitle,
    TaskItem? existingTask,
  }) async {
    final TextEditingController titleController =
        TextEditingController(text: existingTask?.title ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: existingTask?.description ?? '');
    final TextEditingController newCategoryController = TextEditingController();
    DateTime? selectedDeadline = existingTask?.deadline;
    String selectedCategory = existingTask?.category ?? _defaultCategory;

    return showDialog<TaskItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> createCategory() async {
              final String newCategory = newCategoryController.text.trim();
              if (newCategory.isEmpty) {
                return;
              }

              await _addCategory(newCategory);

              if (!dialogContext.mounted) {
                return;
              }

              setDialogState(() {
                selectedCategory = newCategory;
              });
              newCategoryController.clear();
            }

            Future<void> pickDeadline() async {
              final DateTime today = _dateOnly(DateTime.now());
              final DateTime initialDate = selectedDeadline == null
                  ? today
                  : (_dateOnly(selectedDeadline!).isBefore(today)
                      ? today
                      : _dateOnly(selectedDeadline!));

              final DateTime? pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: initialDate,
                firstDate: today,
                lastDate: DateTime(2100),
              );

              if (pickedDate == null) {
                return;
              }

              if (!dialogContext.mounted) {
                return;
              }

              final TimeOfDay initialTime = selectedDeadline == null
                  ? TimeOfDay.now()
                  : TimeOfDay.fromDateTime(selectedDeadline!);

              final TimeOfDay? pickedTime = await showTimePicker(
                context: dialogContext,
                initialTime: initialTime,
              );

              if (pickedTime == null) {
                return;
              }

              setDialogState(() {
                selectedDeadline = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            final String deadlineLabel = selectedDeadline == null
                ? 'No deadline selected'
                : _formatDeadlineLabel(dialogContext, selectedDeadline!);

            return AlertDialog(
              title: Text(dialogTitle),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      initialValue: _categories.contains(selectedCategory)
                          ? selectedCategory
                          : _defaultCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: _categories
                          .map(
                            (String category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: newCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'Create new category',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        TextButton(
                          onPressed: createCategory,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Deadline: $deadlineLabel',
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        TextButton.icon(
                          onPressed: pickDeadline,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Pick deadline'),
                        ),
                        if (selectedDeadline != null)
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedDeadline = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final String description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      TaskItem(
                        title: title,
                        description: description.isEmpty ? 'No description provided' : description,
                        deadline: selectedDeadline,
                        category: selectedCategory,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editTask(int index) async {
    if (index < 0 || index >= _tasks.length) {
      return;
    }

    final task = _tasks[index];
    final TaskItem? updatedTask = await _showTaskDialog(
      dialogTitle: 'Edit Task',
      existingTask: task,
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
    final TaskItem? newTask = await _showTaskDialog(
      dialogTitle: 'Add New Task',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double halfWidth = (constraints.maxWidth - 8.0) / 2;

                return Row(
                  children: <Widget>[
                    SizedBox(
                      width: halfWidth,
                      child: ElevatedButton.icon(
                        onPressed: _toggleFilter,
                        icon: const Icon(Icons.filter_list),
                        label: Text(
                          "Status: $_filterLabel",
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(40.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    SizedBox(
                      width: halfWidth,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _currentCategoryFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 12.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          labelText: 'Category',
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All categories', overflow: TextOverflow.ellipsis),
                          ),
                          ..._categories.map(
                            (String category) => DropdownMenuItem<String?>(
                              value: category,
                              child: Text(category, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: _toggleCategoryFilter,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Task Cards Section
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              itemCount: _filteredTasks.length,
              buildDefaultDragHandles: false,
              onReorderItem: _reorderVisibleTasks,
              itemBuilder: (context, index) {
                final TaskItem task = _filteredTasks[index];
                final int originalIndex = _tasks.indexOf(task);

                return TaskCard(
                  key: ValueKey(task),
                  task: task,
                  reorderIndex: index,
                  isReorderable: true,
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
  final bool isReorderable;
  final int? reorderIndex;
  final ValueChanged<bool> onCompletionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.isReorderable = false,
    this.reorderIndex,
    required this.onCompletionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: <Widget>[
            if (isReorderable && reorderIndex != null)
              ReorderableDragStartListener(
                index: reorderIndex!,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.drag_handle,
                    size: 20.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isCompleted ? Colors.green : Colors.grey,
                size: 22.0,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
              onPressed: () {
                onCompletionChanged(!task.isCompleted);
              },
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(task.category),
                      labelStyle: const TextStyle(fontSize: 11.0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  if (task.deadline != null) ...<Widget>[
                    const SizedBox(height: 4.0),
                    Text(
                      'Deadline: ${_formatDeadlineLabel(context, task.deadline!)}',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: task.deadline!.isBefore(DateTime.now())
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      getDeadlineCountdownText(task.deadline!),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: task.deadline!.isBefore(DateTime.now())
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.brown,
                  iconSize: 20.0,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  iconSize: 20.0,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
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