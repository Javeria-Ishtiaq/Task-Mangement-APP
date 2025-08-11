import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 25), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TaskHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1A237E),
              Color(0xFF3949AB),
              Color(0xFF6C63FF)
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.task_alt, color: Colors.white, size: 72),
              ),
              const SizedBox(height: 16),
              Text(
                'Task Manager',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  Task({required this.id, required this.title, this.isComplete = false});

  final String id;
  final String title;
  bool isComplete;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isComplete': isComplete,
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isComplete: json['isComplete'] as bool? ?? false);
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  static const String _storageKey = 'tasks_v1';
  final List<Task> _tasks = <Task>[];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    _tasks
      ..clear()
      ..addAll(decoded.map(
          (dynamic e) => Task.fromJson(Map<String, dynamic>.from(e as Map))));
    if (mounted) setState(() {});
  }

  Future<void> _persistTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_tasks.map((Task t) => t.toJson()).toList(growable: false));
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _showAddTaskDialog() async {
    final TextEditingController controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter task title',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Add'),
            ),
          ],
        );
      },
    );
    final String title = controller.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _tasks.add(Task(id: UniqueKey().toString(), title: title));
    });
    await _persistTasks();
  }

  Future<void> _toggleComplete(Task task, bool? value) async {
    setState(() {
      task.isComplete = value ?? false;
    });
    await _persistTasks();
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.removeWhere((Task t) => t.id == task.id);
    });
    await _persistTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Removed top-right action to use a more prominent FAB instead
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF6F7FB), Color(0xFFE3E7FF)],
          ),
        ),
        child: _tasks.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: _tasks.length,
                itemBuilder: (BuildContext context, int index) {
                  final Task task = _tasks[index];
                  return Dismissible(
                    key: ValueKey<String>(task.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteTask(task),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: CheckboxListTile(
                        value: task.isComplete,
                        onChanged: (bool? value) =>
                            _toggleComplete(task, value),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isComplete
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isComplete ? Colors.grey : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        secondary: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteTask(task),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 28, bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add, size: 24),
          label: const Text('Add Task'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child:
                Icon(Icons.checklist, size: 64, color: Colors.indigo.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade800, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the + button to add your first task',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
