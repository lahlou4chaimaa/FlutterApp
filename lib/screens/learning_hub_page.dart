
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearningHubPage extends StatefulWidget {
  const LearningHubPage({super.key});

  @override
  State<LearningHubPage> createState() => _LearningHubPageState();
}

class _LearningHubPageState extends State<LearningHubPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  int selectedTab = 0;
  String selectedCategory = 'All';
  bool isLoading = false;
  bool isSaving = false;

  List<Map<String, dynamic>> personalResources = [];
  final Set<String> completedCatalog = {};

  final List<Map<String, dynamic>> catalog = [
    {
      'id': 'flutter',
      'title': 'Flutter Development',
      'description':
          'Learn to build modern mobile applications with Flutter and Dart.',
      'category': 'Development',
      'type': 'Course',
      'duration': 120,
      'url': 'https://docs.flutter.dev/',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF3978F6),
      'level': 'Beginner',
    },
    {
      'id': 'python',
      'title': 'Python Fundamentals',
      'description':
          'Understand Python basics, functions, collections and object-oriented programming.',
      'category': 'Programming',
      'type': 'Course',
      'duration': 90,
      'url': 'https://docs.python.org/3/tutorial/',
      'icon': Icons.code_rounded,
      'color': Color(0xFFED9B36),
      'level': 'Beginner',
    },
    {
      'id': 'sql',
      'title': 'SQL & Databases',
      'description':
          'Learn SQL queries, database relationships and data manipulation.',
      'category': 'Database',
      'type': 'Tutorial',
      'duration': 75,
      'url': 'https://www.postgresql.org/docs/',
      'icon': Icons.storage_rounded,
      'color': Color(0xFF805AD5),
      'level': 'Beginner',
    },
    {
      'id': 'git',
      'title': 'Git & GitHub',
      'description':
          'Master version control, branches, commits and collaborative workflows.',
      'category': 'Tools',
      'type': 'Guide',
      'duration': 45,
      'url': 'https://docs.github.com/en/get-started',
      'icon': Icons.account_tree_rounded,
      'color': Color(0xFFE56B45),
      'level': 'Beginner',
    },
    {
      'id': 'network',
      'title': 'Computer Networks',
      'description':
          'Explore network fundamentals, protocols, addressing and routing.',
      'category': 'Networks',
      'type': 'Course',
      'duration': 100,
      'url': 'https://www.cisco.com/site/us/en/learn/training-certifications/index.html',
      'icon': Icons.lan_rounded,
      'color': Color(0xFF159A82),
      'level': 'Intermediate',
    },
    {
      'id': 'api',
      'title': 'REST API Fundamentals',
      'description':
          'Understand HTTP methods, endpoints, requests, responses and API testing.',
      'category': 'Development',
      'type': 'Tutorial',
      'duration': 60,
      'url': 'https://developer.mozilla.org/en-US/docs/Web/HTTP',
      'icon': Icons.api_rounded,
      'color': Color(0xFFCF5685),
      'level': 'Beginner',
    },
  ];

  final List<String> categories = [
    'All',
    'Development',
    'Programming',
    'Database',
    'Tools',
    'Networks',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    loadPersonalResources();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF172B4D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> loadPersonalResources() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          personalResources = [];
          isLoading = false;
        });
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('learning_items')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        personalResources = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Unable to load resources. Check your Supabase table.');
      debugPrint('Learning Hub load error: $error');
    }
  }

  Future<void> addResource({
    required String title,
    required String description,
    required String category,
    required String url,
    required String type,
    required int duration,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('Please sign in to save your resources.');
      return;
    }

    setState(() => isSaving = true);

    try {
      await supabase.from('learning_items').insert({
        'user_id': user.id,
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'resource_url': url.trim(),
        'resource_type': type,
        'duration_minutes': duration,
        'progress': 0,
      });

      await loadPersonalResources();

      if (!mounted) return;
      showMessage('Resource added successfully.');
    } catch (error) {
      if (!mounted) return;

      showMessage('Could not save the resource. Check the table and policies.');
      debugPrint('Learning Hub insert error: $error');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> updateProgress(
    Map<String, dynamic> resource,
    int progress,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('learning_items')
          .update({'progress': progress})
          .eq('id', resource['id'])
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        final index = personalResources.indexWhere(
          (item) => item['id'] == resource['id'],
        );

        if (index != -1) {
          personalResources[index]['progress'] = progress;
        }
      });
    } catch (error) {
      showMessage('Could not update progress.');
      debugPrint('Learning Hub progress error: $error');
    }
  }

  Future<void> deleteResource(Map<String, dynamic> resource) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('learning_items')
          .delete()
          .eq('id', resource['id'])
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        personalResources.removeWhere(
          (item) => item['id'] == resource['id'],
        );
      });

      showMessage('Resource deleted.');
    } catch (error) {
      showMessage('Could not delete the resource.');
      debugPrint('Learning Hub delete error: $error');
    }
  }

  List<Map<String, dynamic>> get visibleResources {
    final source = selectedTab == 0 ? catalog : personalResources;

    return source.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final description =
          (item['description'] ?? '').toString().toLowerCase();
      final query = searchController.text.trim().toLowerCase();

      final category = selectedTab == 0
          ? (item['category'] ?? '').toString()
          : (item['category'] ?? 'Personal').toString();

      final matchesSearch =
          title.contains(query) || description.contains(query);

      final matchesCategory = selectedCategory == 'All' ||
          (selectedCategory == 'Personal' && selectedTab == 1) ||
          category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  int get personalCompletedCount => personalResources
      .where((item) => (item['progress'] as num? ?? 0) >= 100)
      .length;

  int get totalCompletedCount =>
      personalCompletedCount + completedCatalog.length;

  void openResource(Map<String, dynamic> resource) {
    final url = (resource['resource_url'] ?? resource['url'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE3EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resource details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (resource['title'] ?? 'Untitled').toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (resource['description'] ?? 'No description available.')
                      .toString(),
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: Color(0xFF3978F6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          url.isEmpty ? 'No URL provided' : url,
                          style: const TextStyle(
                            color: Color(0xFF3978F6),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showMessage(
                        'Copy the URL above into your browser to open it.',
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('View resource link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3978F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAddResourceDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();

    String category = 'Development';
    String type = 'Course';
    int duration = 30;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Add a resource',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172B4D),
                ),
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: _inputDecoration(
                            'Resource title',
                            Icons.title_rounded,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Enter a title'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'Description',
                            Icons.notes_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlController,
                          keyboardType: TextInputType.url,
                          decoration: _inputDecoration(
                            'Resource URL (https://...)',
                            Icons.link_rounded,
                          ),
                          validator: (value) {
                            final uri = Uri.tryParse(value?.trim() ?? '');
                            if (uri == null ||
                                !uri.hasScheme ||
                                !(uri.scheme == 'https' ||
                                    uri.scheme == 'http') ||
                                uri.host.isEmpty) {
                              return 'Enter a valid HTTP or HTTPS URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration:
                              _inputDecoration('Category', Icons.category),
                          items: const [
                            'Development',
                            'Programming',
                            'Database',
                            'Tools',
                            'Networks',
                          ]
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration:
                              _inputDecoration('Resource type', Icons.bookmark),
                          items: const [
                            'Course',
                            'Tutorial',
                            'Article',
                            'Documentation',
                            'Video',
                            'Book',
                            'Other',
                          ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => type = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Estimated duration: $duration minutes',
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Slider(
                          value: duration.toDouble(),
                          min: 15,
                          max: 240,
                          divisions: 15,
                          activeColor: const Color(0xFF3978F6),
                          onChanged: (value) {
                            setDialogState(() => duration = value.round());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    titleController.dispose();
                    descriptionController.dispose();
                    urlController.dispose();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final title = titleController.text;
                          final description = descriptionController.text;
                          final url = urlController.text;

                          Navigator.pop(dialogContext);

                          await addResource(
                            title: title,
                            description: description,
                            category: category,
                            url: url,
                            type: type,
                            duration: duration,
                          );

                          titleController.dispose();
                          descriptionController.dispose();
                          urlController.dispose();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3978F6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save resource'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6EBF3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF3978F6),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resources = visibleResources;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),
        foregroundColor: const Color(0xFF172B4D),
        elevation: 0,
        title: const Text(
          'Learning Hub',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh resources',
            onPressed: loadPersonalResources,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: isSaving ? null : showAddResourceDialog,
              backgroundColor: const Color(0xFF3978F6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add resource'),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadPersonalResources,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _buildHero(),
              const SizedBox(height: 20),
              _buildStats(),
              const SizedBox(height: 26),
              _buildTabs(),
              const SizedBox(height: 20),
              _buildSearch(),
              const SizedBox(height: 14),
              _buildCategoryFilters(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedTab == 0
                          ? 'Explore resources'
                          : 'My resources',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                  ),
                  Text(
                    '${resources.length} ${resources.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (selectedTab == 1 && isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (resources.isEmpty)
                _buildEmptyState()
              else
                ...resources.map(_buildResourceCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173D8F), Color(0xFF3978F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3978F6).withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'YOUR PERSONAL LEARNING SPACE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Learn something\nnew today.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Discover resources, build your skills and track your progress.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${catalog.length} starter resources available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.library_books_rounded,
            label: 'My resources',
            value: '${personalResources.length}',
            color: const Color(0xFF3978F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: '$totalCompletedCount',
            color: const Color(0xFF159A82),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.explore_rounded,
            label: 'Discover',
            value: '${catalog.length}',
            color: const Color(0xFF805AD5),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAF0F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabButton(
            label: 'Explore',
            icon: Icons.explore_rounded,
            index: 0,
          ),
          _tabButton(
            label: 'My Resources',
            icon: Icons.bookmarks_rounded,
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
            selectedCategory = 'All';
            searchController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF3978F6)
                    : const Color(0xFF718096),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF172B4D)
                        : const Color(0xFF718096),
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search courses, topics, resources...',
        hintStyle: const TextStyle(
          color: Color(0xFF9AA7BA),
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF718096),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6EBF3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6EBF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3978F6)),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final filters = selectedTab == 0
        ? categories.where((category) => category != 'Personal').toList()
        : categories;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = filters[index];
          final selected = selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => selectedCategory = category),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF3978F6),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF3978F6)
                  : const Color(0xFFE6EBF3),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF718096),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> item) {
    final isCatalog = selectedTab == 0;
    final title = (item['title'] ?? 'Untitled').toString();
    final description =
        (item['description'] ?? 'No description available.').toString();
    final category = (item['category'] ?? 'Personal').toString();
    final type = (item['resource_type'] ?? item['type'] ?? 'Resource')
        .toString();
    final duration =
        (item['duration_minutes'] ?? item['duration'] ?? 30) as num;
    final progress = ((item['progress'] ?? 0) as num).toInt();
    final id = (item['id'] ?? '').toString();
    final isCompleted =
        isCatalog ? completedCatalog.contains(id) : progress >= 100;

    final icon = isCatalog
        ? item['icon'] as IconData
        : _iconForCategory(category);

    final color = isCatalog
        ? item['color'] as Color
        : _colorForCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAF0F8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openResource(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF172B4D),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _smallTag(category, color),
                            _smallTag(type, const Color(0xFF718096)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCatalog)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDelete(item);
                        }
                      },
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF718096),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Delete resource'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: Color(0xFF718096),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    duration >= 60
                        ? '${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} h'
                        : '${duration.toInt()} min',
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF159A82),
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Color(0xFF159A82),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      isCatalog
                          ? (item['level'] ?? 'Beginner').toString()
                          : '$progress% completed',
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (!isCatalog) ...[
                const SizedBox(height: 11),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEAF0F8),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress >= 100
                            ? 'You have completed this resource'
                            : 'Update your learning progress',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ),
                    PopupMenuButton<int>(
                      tooltip: 'Update progress',
                      onSelected: (value) => updateProgress(item, value),
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: Color(0xFF3978F6),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 0, child: Text('Not started · 0%')),
                        PopupMenuItem(value: 25, child: Text('Started · 25%')),
                        PopupMenuItem(value: 50, child: Text('Halfway · 50%')),
                        PopupMenuItem(value: 75, child: Text('Almost done · 75%')),
                        PopupMenuItem(value: 100, child: Text('Completed · 100%')),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isCompleted) {
                          completedCatalog.remove(id);
                        } else {
                          completedCatalog.add(id);
                        }
                      });
                    },
                    icon: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCompleted ? 'Mark as not completed' : 'Mark as completed',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isCompleted
                          ? const Color(0xFF159A82)
                          : const Color(0xFF3978F6),
                      side: BorderSide(
                        color: isCompleted
                            ? const Color(0xFFB8E8D9)
                            : const Color(0xFFD9E5FB),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAF0F8)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 32,
              color: Color(0xFF3978F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedTab == 0
                ? 'No matching resources'
                : 'Your learning space is empty',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedTab == 0
                ? 'Try another keyword or category.'
                : 'Save courses, tutorials and useful links here to keep everything organized.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF718096),
              height: 1.5,
              fontSize: 12,
            ),
          ),
          if (selectedTab == 1) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: showAddResourceDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first resource'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3978F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resource?'),
        content: Text(
          'Are you sure you want to delete "${resource['title']}"?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteResource(resource);
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Development':
        return Icons.phone_android_rounded;
      case 'Programming':
        return Icons.code_rounded;
      case 'Database':
        return Icons.storage_rounded;
      case 'Tools':
        return Icons.build_circle_rounded;
      case 'Networks':
        return Icons.lan_rounded;
      default:
        return Icons.bookmark_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Development':
        return const Color(0xFF3978F6);
      case 'Programming':
        return const Color(0xFFED9B36);
      case 'Database':
        return const Color(0xFF805AD5);
      case 'Tools':
        return const Color(0xFFE56B45);
      case 'Networks':
        return const Color(0xFF159A82);
      default:
        return const Color(0xFF718096);
    }
  }
}
