import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'tasks_page.dart';
import 'settings_page.dart';
import 'learning_hub_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryBlue = Color(0xFF3157D5);
  static const Color darkBlue = Color(0xFF172B65);
  static const Color backgroundColor = Color(0xFFF5F7FC);

  void _openLearningHub(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LearningHubPage()),
    );
  }

  void _openTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TasksPage()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of SkillUp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final metadataName = user?.userMetadata?['name']?.toString();
    final email = user?.email ?? '';
    final firstName = (metadataName != null && metadataName.trim().isNotEmpty)
        ? metadataName.trim().split(' ').first
        : (email.contains('@') ? email.split('@').first : 'Student');

    final displayName = firstName.isNotEmpty ? firstName : 'Student';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBlue),
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: primaryBlue, size: 27),
            SizedBox(width: 9),
            Text(
              'SkillUp',
              style: TextStyle(
                color: darkBlue,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SKILLUP MEMBER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _drawerItem(
                context,
                icon: Icons.dashboard_rounded,
                title: 'Dashboard',
                selected: true,
                onTap: () => Navigator.pop(context),
              ),

              _drawerItem(
                context,
                icon: Icons.check_circle_outline_rounded,
                title: 'My Tasks',
                onTap: () {
                  Navigator.pop(context);
                  _openTasks(context);
                },
              ),

              _drawerItem(
                context,
                icon: Icons.auto_stories_rounded,
                title: 'Learning Hub',
                onTap: () {
                  Navigator.pop(context);
                  _openLearningHub(context);
                },
              ),

              _drawerItem(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _openSettings(context);
                },
              ),

              const Spacer(),

              const Divider(indent: 20, endIndent: 20),

              _drawerItem(
                context,
                icon: Icons.logout_rounded,
                title: 'Log out',
                iconColor: Colors.redAccent,
                titleColor: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Icon(
                        Icons.school_rounded,
                        size: 125,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'YOUR PERSONAL WORKSPACE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Hello, $displayName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Build better habits, learn new skills, '
                          'and make progress every day.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: () => _openLearningHub(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore Learning Hub',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Section heading
              const Text(
                'Your workspace',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Everything you need to stay organized and keep learning.',
                style: TextStyle(
                  color: Colors.blueGrey.shade600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // Main feature cards
              _featureCard(
                context,
                icon: Icons.check_circle_outline_rounded,
                title: 'My Tasks',
                description:
                    'Organize your work, manage deadlines, '
                    'and track your progress.',
                tag: 'PRODUCTIVITY',
                iconColor: const Color(0xFF5275E8),
                iconBackground: const Color(0xFFEDF1FF),
                onTap: () => _openTasks(context),
              ),

              const SizedBox(height: 15),

              _featureCard(
                context,
                icon: Icons.auto_stories_rounded,
                title: 'Learning Hub',
                description:
                    'Discover learning resources and manage '
                    'your personal study collection.',
                tag: 'LEARNING',
                iconColor: const Color(0xFF168B83),
                iconBackground: const Color(0xFFE6F7F4),
                onTap: () => _openLearningHub(context),
              ),

              const SizedBox(height: 15),

              _featureCard(
                context,
                icon: Icons.manage_accounts_rounded,
                title: 'My Profile & Settings',
                description:
                    'View your account information and '
                    'manage your application preferences.',
                tag: 'YOUR ACCOUNT',
                iconColor: const Color(0xFF9A63C7),
                iconBackground: const Color(0xFFF4ECFB),
                onTap: () => _openSettings(context),
              ),

              const SizedBox(height: 28),

              // Daily reminder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCE5FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A little progress every day',
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Choose one task or learning resource '
                            'and take the next step toward your goals.',
                            style: TextStyle(
                              color: Color(0xFF526487),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: Text(
                  'SkillUp  •  Learn. Organize. Grow.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? iconColor,
    Color? titleColor,
  }) {
    final itemColor =
        titleColor ?? (selected ? primaryBlue : const Color(0xFF526078));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFEDF1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        leading: Icon(icon, color: iconColor ?? itemColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.circle, color: primaryBlue, size: 8)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String tag,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 13),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.blueGrey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
