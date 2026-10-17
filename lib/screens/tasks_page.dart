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
  String sortBy = 'Due date';

  final categories = ['Study', 'Work', 'Personal', 'Project', 'Other'];

  static const navy = Color(0xFF172B4D);
  static const blue = Color(0xFF4776E6);
  static const background = Color(0xFFF5F7FC);
  static const muted = Color(0xFF7D8BA3);
  static const borderColor = Color(0xFFE8EDF5);

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
    if (user == null) throw Exception('User not authenticated');
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
      showMessage('Could not load tasks. Check your connection and database.');
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
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  bool isCompleted(Map<String, dynamic> task) {
    return task['is_completed'] == true ||
        task['is_completed']?.toString() == 'true' ||
        task['status'] == 'Completed';
  }

  DateTime? dueDateOf(Map<String, dynamic> task) {
    final value = task['due_date'];
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool isOverdue(Map<String, dynamic> task) {
    final date = dueDateOf(task);
    return !isCompleted(task) &&
        date != null &&
        DateTime(date.year, date.month, date.day).isBefore(today);
  }

  bool isToday(Map<String, dynamic> task) {
    final date = dueDateOf(task);
    return !isCompleted(task) &&
        date != null &&
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool isUpcoming(Map<String, dynamic> task) {
    final date = dueDateOf(task);
    return !isCompleted(task) &&
        date != null &&
        DateTime(date.year, date.month, date.day).isAfter(today);
  }

  int get completedCount => tasks.where(isCompleted).length;
  int get pendingCount => tasks.where((t) => !isCompleted(t)).length;
  int get overdueCount => tasks.where(isOverdue).length;
  int get todayCount => tasks.where(isToday).length;

  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  List<Map<String, dynamic>> get visibleTasks {
    final query = search.trim().toLowerCase();

    final result = tasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();
      final description = (task['description'] ?? '').toString().toLowerCase();
      final category = (task['category'] ?? '').toString().toLowerCase();

      if (query.isNotEmpty &&
          !title.contains(query) &&
          !description.contains(query) &&
          !category.contains(query)) {
        return false;
      }

      switch (filter) {
        case 'To do':
          return !isCompleted(task);
        case 'Completed':
          return isCompleted(task);
        case 'Overdue':
          return isOverdue(task);
        case 'Today':
          return isToday(task);
        case 'Upcoming':
          return isUpcoming(task);
        default:
          return true;
      }
    }).toList();

    result.sort((a, b) {
      if (sortBy == 'Priority') {
        const order = {'High': 0, 'Medium': 1, 'Low': 2};
        return (order[a['priority']] ?? 1).compareTo(order[b['priority']] ?? 1);
      }

      if (sortBy == 'Title') {
        return (a['title'] ?? '').toString().toLowerCase().compareTo(
          (b['title'] ?? '').toString().toLowerCase(),
        );
      }

      final dateA = dueDateOf(a);
      final dateB = dueDateOf(b);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    return result;
  }

  Future<void> saveTask({
    dynamic id,
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
        'description': description.trim().isEmpty ? null : description.trim(),
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
      showMessage('Could not save the task. Check the tasks table columns.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> toggleTask(Map<String, dynamic> task) async {
    if (saving) return;

    final dynamic id = task['id'];
    final bool previousValue = isCompleted(task);
    final bool newValue = !previousValue;

    // Mise à jour immédiate de l'interface.
    setState(() {
      final index = tasks.indexWhere((t) => t['id'] == id);

      if (index != -1) {
        tasks[index]['is_completed'] = newValue;
        tasks[index]['status'] = newValue ? 'Completed' : 'To Do';
      }
    });

    try {
      await supabase
          .from('tasks')
          .update({
            'is_completed': newValue,
            'status': newValue ? 'Completed' : 'To Do',
          })
          .eq('id', id)
          .eq('user_id', userId);

      if (!mounted) return;

      showMessage(newValue ? 'Task completed.' : 'Task marked as pending.');
    } catch (e) {
      // Annuler le changement visuel si Supabase refuse la mise à jour.
      if (!mounted) return;

      setState(() {
        final index = tasks.indexWhere((t) => t['id'] == id);

        if (index != -1) {
          tasks[index]['is_completed'] = previousValue;
          tasks[index]['status'] = previousValue ? 'Completed' : 'To Do';
        }
      });

      showMessage('Update failed: $e');
    }
  }

  Future<void> deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete task?'),
        content: Text(
          '“${task['title'] ?? 'Untitled task'}” will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9485F),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase
          .from('tasks')
          .delete()
          .eq('id', task['id'])
          .eq('user_id', userId);

      await loadTasks();
      showMessage('Task deleted.');
    } catch (e) {
      showMessage('Could not delete this task.');
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
    DateTime? dueDate = dueDateOf(task ?? {});

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE3EF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    task == null ? 'Create a task' : 'Edit task',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Break your goals into clear, manageable actions.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _fieldLabel('Task title'),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    maxLength: 100,
                    decoration: _inputDecoration(
                      'e.g. Finish the Flutter dashboard',
                      Icons.edit_note_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Description'),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Add details or next steps...',
                      Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('Priority'),
                  Wrap(
                    spacing: 8,
                    children: ['Low', 'Medium', 'High'].map((item) {
                      final selected = priority == item;
                      final color = _priorityColor(item);

                      return ChoiceChip(
                        label: Text(item),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: color.withValues(alpha: 0.14),
                        labelStyle: TextStyle(
                          color: selected ? color : navy,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(color: selected ? color : borderColor),
                        onSelected: (_) {
                          setSheetState(() => priority = item);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Category'),
                  DropdownButtonFormField<String>(
                    value: categories.contains(category) ? category : 'Study',
                    decoration: _inputDecoration(
                      'Choose a category',
                      Icons.folder_open_outlined,
                    ),
                    items: categories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('Due date'),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? today,
                        firstDate: today,
                        lastDate: DateTime(2100),
                      );

                      if (selected != null) {
                        setSheetState(() => dueDate = selected);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dueDate == null
                                  ? 'Add a deadline (optional)'
                                  : _formatDate(dueDate!),
                              style: TextStyle(
                                color: dueDate == null ? muted : navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (dueDate != null)
                            IconButton(
                              tooltip: 'Remove deadline',
                              onPressed: () {
                                setSheetState(() => dueDate = null);
                              },
                              icon: const Icon(Icons.close, size: 19),
                            )
                          else
                            const Icon(Icons.chevron_right, color: muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () => saveTask(
                              id: task?['id'],
                              title: titleController.text,
                              description: descriptionController.text,
                              priority: priority,
                              category: category,
                              dueDate: dueDate,
                            ),
                      icon: saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              task == null
                                  ? Icons.add_rounded
                                  : Icons.check_rounded,
                            ),
                      label: Text(
                        saving
                            ? 'Saving...'
                            : task == null
                            ? 'Create task'
                            : 'Save changes',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (loading && tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 70),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      _buildOverview(),
                      const SizedBox(height: 24),
                      _buildTodayPanel(),
                      const SizedBox(height: 24),
                      _buildSearch(),
                      const SizedBox(height: 18),
                      _buildFilters(),
                      const SizedBox(height: 24),
                      _buildTaskListHeader(),
                      const SizedBox(height: 14),
                      if (loading)
                        const LinearProgressIndicator(minHeight: 2)
                      else if (visibleTasks.isEmpty)
                        _buildEmptyState()
                      else
                        ...visibleTasks.map(_buildTaskCard),
                    ],
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
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4776E6), Color(0xFF3154B8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.checklist_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SKILLUP / ORGANIZER',
                style: TextStyle(
                  color: blue,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'My Tasks',
                style: TextStyle(
                  color: navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Refresh',
          onPressed: loadTasks,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            foregroundColor: navy,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172B4D), Color(0xFF294D83), Color(0xFF315FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.13),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR PRODUCTIVITY',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tasks.isEmpty ? 'Getting started' : '$completedCount done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 43,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 9, bottom: 5),
                child: Text(
                  'of tasks completed',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9ADCF9)),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _overviewStat('Total', tasks.length, Icons.layers_outlined),
              _overviewStat('To do', pendingCount, Icons.schedule_rounded),
              _overviewStat(
                'Overdue',
                overdueCount,
                Icons.warning_amber_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(String label, int value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white70),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPanel() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.today_outlined, color: blue, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your focus today',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayCount == 0
                      ? 'No tasks due today. Plan your next step.'
                      : '$todayCount ${todayCount == 1 ? 'task' : 'tasks'} due today.',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => filter = 'Today');
            },
            child: const Text('View'),
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
        hintText: 'Search tasks, descriptions, categories...',
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: muted),
        suffixIcon: search.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  searchController.clear();
                  setState(() => search = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: blue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      'All',
      'To do',
      'Today',
      'Upcoming',
      'Completed',
      'Overdue',
    ];

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
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: selected ? navy : borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => setState(() => filter = item),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskListHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your tasks',
                style: TextStyle(
                  color: navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${visibleTasks.length} ${visibleTasks.length == 1 ? 'task' : 'tasks'} shown',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 11, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: ['Due date', 'Priority', 'Title']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => sortBy = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final completed = isCompleted(task);
    final overdue = isOverdue(task);
    final priority = task['priority']?.toString() ?? 'Medium';
    final category = task['category']?.toString() ?? 'Study';
    final dueDate = dueDateOf(task);
    final color = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: overdue ? const Color(0xFFFFD8DE) : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Checkbox(
              value: completed,
              activeColor: blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (_) => toggleTask(task),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  task['title']?.toString() ?? 'Untitled task',
                  style: TextStyle(
                    color: completed ? muted : navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((task['description'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(category, blue),
                    _tag(priority, color),
                    if (dueDate != null)
                      _tag(
                        overdue
                            ? 'Overdue · ${_formatDate(dueDate)}'
                            : _formatDate(dueDate),
                        overdue ? const Color(0xFFD9485F) : muted,
                      ),
                    if (completed) _tag('Completed', const Color(0xFF258567)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Task actions',
            icon: const Icon(Icons.more_horiz_rounded, color: muted),
            onSelected: (value) {
              if (value == 'edit') openTaskForm(task: task);
              if (value == 'delete') deleteTask(task);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 19),
                    SizedBox(width: 10),
                    Text('Edit task'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Color(0xFFD9485F),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Delete task',
                      style: TextStyle(color: Color(0xFFD9485F)),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
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
    final hasTasks = tasks.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              hasTasks ? Icons.search_off_rounded : Icons.task_alt_rounded,
              size: 34,
              color: blue,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            hasTasks ? 'No matching tasks' : 'Make room for progress',
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasTasks
                ? 'Try a different filter or search term.'
                : 'Create your first task and keep your goals organized.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          if (!hasTasks) ...[
            const SizedBox(height: 19),
            FilledButton.icon(
              onPressed: () => openTaskForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create first task'),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                searchController.clear();
                setState(() {
                  search = '';
                  filter = 'All';
                });
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: navy,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      prefixIcon: Icon(icon, color: muted, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAFBFE),
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.4),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFD9485F);
      case 'Low':
        return const Color(0xFF258567);
      default:
        return const Color(0xFFD58A24);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
