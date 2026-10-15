
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> tasks = [];
  bool loading = true;
  bool saving = false;

  String filter = 'All';
  String search = '';
  String sortBy = 'Date';

  static const navy = Color(0xFF142B4A);
  static const blue = Color(0xFF4776E6);
  static const background = Color(0xFFF5F7FC);

  final categories = [
    'Study',
    'Work',
    'Personal',
    'Project',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String get userId {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user.');
    }
    return user.id;
  }

  Future<void> loadTasks() async {
    if (mounted) setState(() => loading = true);

    try {
      final result = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        tasks = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Unable to load tasks. Check your connection.');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  bool isCompleted(Map<String, dynamic> task) {
    return task['is_completed'] == true ||
        task['status'] == 'Completed';
  }

  bool isOverdue(Map<String, dynamic> task) {
    if (isCompleted(task) || task['due_date'] == null) {
      return false;
    }

    final date = DateTime.tryParse(task['due_date'].toString());
    if (date == null) return false;

    final due = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);

    return due.isBefore(currentDay);
  }

  List<Map<String, dynamic>> get visibleTasks {
    var result = tasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();
      final description =
          (task['description'] ?? '').toString().toLowerCase();
      final query = search.trim().toLowerCase();

      if (query.isNotEmpty &&
          !title.contains(query) &&
          !description.contains(query)) {
        return false;
      }

      switch (filter) {
        case 'To Do':
          return !isCompleted(task);
        case 'Completed':
          return isCompleted(task);
        case 'Overdue':
          return isOverdue(task);
        default:
          return true;
      }
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'Priority') {
        const order = {'High': 0, 'Medium': 1, 'Low': 2};
        return (order[a['priority']] ?? 1)
            .compareTo(order[b['priority']] ?? 1);
      }

      if (sortBy == 'Title') {
        return (a['title'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo(
              (b['title'] ?? '').toString().toLowerCase(),
            );
      }

      final dateA = DateTime.tryParse(
        (a['due_date'] ?? '9999-12-31').toString(),
      );
      final dateB = DateTime.tryParse(
        (b['due_date'] ?? '9999-12-31').toString(),
      );

      return (dateA ?? DateTime(9999))
          .compareTo(dateB ?? DateTime(9999));
    });

    return result;
  }

  int get completedCount => tasks.where(isCompleted).length;

  int get pendingCount => tasks.where((t) => !isCompleted(t)).length;

  int get overdueCount => tasks.where(isOverdue).length;

  double get progress =>
      tasks.isEmpty ? 0 : completedCount / tasks.length;

  Future<void> saveTask({
    int? id,
    required String title,
    required String description,
    required String priority,
    required String category,
    DateTime? dueDate,
  }) async {
    if (title.trim().isEmpty) {
      showMessage('Please enter a task title.');
      return;
    }

    setState(() => saving = true);

    try {
      final data = <String, dynamic>{
        'title': title.trim(),
        'description':
            description.trim().isEmpty ? null : description.trim(),
        'priority': priority,
        'category': category,
        'due_date': dueDate == null
            ? null
            : '${dueDate.year.toString().padLeft(4, '0')}-'
                '${dueDate.month.toString().padLeft(2, '0')}-'
                '${dueDate.day.toString().padLeft(2, '0')}',
      };

      if (id == null) {
        data['user_id'] = userId;
        data['is_completed'] = false;
        data['status'] = 'To Do';

        await supabase.from('tasks').insert(data);
      } else {
        await supabase
            .from('tasks')
            .update(data)
            .eq('id', id)
            .eq('user_id', userId);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      showMessage(id == null ? 'Task created.' : 'Task updated.');
      await loadTasks();
    } catch (e) {
      showMessage('Unable to save task. Check your database settings.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> toggleTask(Map<String, dynamic> task) async {
    final id = task['id'];
    final completed = !isCompleted(task);

    try {
      await supabase
          .from('tasks')
          .update({
            'is_completed': completed,
            'status': completed ? 'Completed' : 'To Do',
          })
          .eq('id', id)
          .eq('user_id', userId);

      await loadTasks();
    } catch (e) {
      showMessage('Unable to update task.');
    }
  }

  Future<void> deleteTask(Map<String, dynamic> task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Are you sure you want to delete "${task['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('tasks')
          .delete()
          .eq('id', task['id'])
          .eq('user_id', userId);

      await loadTasks();
      showMessage('Task deleted.');
    } catch (e) {
      showMessage('Unable to delete task.');
    }
  }

  Future<void> openTaskForm({Map<String, dynamic>? task}) async {
    final titleController = TextEditingController(
      text: task?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: task?['description']?.toString() ?? '',
    );

    String priority = task?['priority']?.toString() ?? 'Medium';
    String category = task?['category']?.toString() ?? 'Study';

    DateTime? dueDate = task?['due_date'] == null
        ? null
        : DateTime.tryParse(task!['due_date'].toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? 'Create task' : 'Edit task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'What do you need to do?',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add some details...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Priority'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ['Low', 'Medium', 'High']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text('Category'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: categories.contains(category)
                      ? category
                      : 'Study',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    dueDate == null
                        ? 'Set due date'
                        : '${dueDate!.day.toString().padLeft(2, '0')}/'
                            '${dueDate!.month.toString().padLeft(2, '0')}/'
                            '${dueDate!.year}',
                  ),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (selected != null) {
                      setDialogState(() => dueDate = selected);
                    }
                  },
                ),
                if (dueDate != null)
                  TextButton(
                    onPressed: () {
                      setDialogState(() => dueDate = null);
                    },
                    child: const Text('Remove due date'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () => saveTask(
                        id: task?['id'] as int?,
                        title: titleController.text,
                        description: descriptionController.text,
                        priority: priority,
                        category: category,
                        dueDate: dueDate,
                      ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(task == null ? 'Create' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTasks,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildOverview(),
                          const SizedBox(height: 24),
                          _buildSearch(),
                          const SizedBox(height: 16),
                          _buildFilters(),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Your tasks',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: navy,
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: sortBy,
                                underline: const SizedBox(),
                                items: ['Date', 'Priority', 'Title']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text('Sort: $s'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => sortBy = value);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (visibleTasks.isEmpty)
                            _buildEmptyState()
                          else
                            ...visibleTasks.map(_buildTaskCard),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTaskForm(),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: blue,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SKILLUP',
                    style: TextStyle(
                      color: blue,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'My Tasks',
                    style: TextStyle(
                      color: navy,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh tasks',
              onPressed: loadTasks,
              icon: const Icon(Icons.refresh, color: navy),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Plan your work. Track your progress. Stay consistent.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142B4A), Color(0xFF315FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUCTIVITY OVERVIEW',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 7, left: 8),
                child: Text(
                  'completed',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount / ${tasks.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8ED8FF),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat('Total', tasks.length, Icons.list_alt),
              _stat('Pending', pendingCount, Icons.schedule),
              _stat('Overdue', overdueCount, Icons.warning_amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white70),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (value) => setState(() => search = value),
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: search.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() => search = '');
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = ['All', 'Pending', 'Completed', 'Overdue'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final selected = filter == item;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item),
              selected: selected,
              showCheckmark: false,
              selectedColor: navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : navy,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? navy : const Color(0xFFE3E8F2),
                ),
              ),
              onSelected: (_) => setState(() => filter = item),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final completed = isCompleted(task);
    final overdue = isOverdue(task);
    final priority = task['priority']?.toString() ?? 'Medium';
    final dueDate = task['due_date'] == null
        ? null
        : DateTime.tryParse(task['due_date'].toString());

    final priorityColor = switch (priority) {
      'High' => const Color(0xFFD94F59),
      'Low' => const Color(0xFF319C7A),
      _ => const Color(0xFFE59A2F),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: overdue
              ? const Color(0xFFFFD8D8)
              : const Color(0xFFEBEFF6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: completed,
            activeColor: blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (_) => toggleTask(task),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? 'Untitled task',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: completed ? Colors.blueGrey : navy,
                    decoration:
                        completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((task['description'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    task['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(
                      task['category']?.toString() ?? 'Study',
                      const Color(0xFF4776E6),
                    ),
                    _tag(priority, priorityColor),
                    if (dueDate != null)
                      _tag(
                        '${dueDate.day.toString().padLeft(2, '0')}/'
                        '${dueDate.month.toString().padLeft(2, '0')}/'
                        '${dueDate.year}',
                        overdue ? Colors.red : Colors.blueGrey,
                      ),
                    if (overdue) _tag('OVERDUE', Colors.red),
                    if (completed) _tag('DONE', Colors.green),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
            onSelected: (value) {
              if (value == 'edit') {
                openTaskForm(task: task);
              } else if (value == 'delete') {
                deleteTask(task);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt,
            size: 50,
            color: Color(0xFF9BAAC2),
          ),
          const SizedBox(height: 12),
          Text(
            tasks.isEmpty ? 'Your task list is empty' : 'No matching tasks',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            tasks.isEmpty
                ? 'Create your first task and start tracking your progress.'
                : 'Try another filter or search term.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 13,
            ),
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => openTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Create your first task'),
            ),
          ],
        ],
      ),
    );
  }
}
