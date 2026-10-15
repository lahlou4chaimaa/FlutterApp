
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'tasks_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
        ),
      );
    }
  }

  void _openTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TasksPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final email = user?.email ?? 'No email available';
    final metadata = user?.userMetadata ?? {};

    final storedName = metadata['nom']?.toString().trim();

    final String name;

    if (storedName != null && storedName.isNotEmpty) {
      name = storedName;
    } else if (email.contains('@')) {
      name = email.split('@').first;
    } else {
      name = 'Student';
    }

    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172B4D),
        elevation: 0,
        title: const Text(
          'SkillUp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              _showComingSoon(context, 'Notifications');
            },
            icon: const Icon(Icons.notifications_none_rounded),
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
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3157D5),
                      Color(0xFF6485F0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Color(0xFF3157D5),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _drawerItem(
                icon: Icons.dashboard_rounded,
                title: 'Dashboard',
                onTap: () => Navigator.pop(context),
              ),

              _drawerItem(
                icon: Icons.check_circle_outline_rounded,
                title: 'My Tasks',
                onTap: () {
                  Navigator.pop(context);
                  _openTasks(context);
                },
              ),

              _drawerItem(
                icon: Icons.psychology_outlined,
                title: 'My Skills',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'My Skills');
                },
              ),

              _drawerItem(
                icon: Icons.work_outline_rounded,
                title: 'My Applications',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'My Applications');
                },
              ),

              _drawerItem(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'My Profile');
                },
              ),

              _drawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Settings');
                },
              ),

              const Spacer(),

              const Divider(height: 1),

              _drawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                iconColor: Colors.redAccent,
                textColor: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your learning space',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Hello, $name!',
              style: const TextStyle(
                color: Color(0xFF172B4D),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Plan your goals, develop your skills, '
              'and prepare for your future.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Main banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3157D5),
                    Color(0xFF6485F0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Small steps, big achievements.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'Build better habits and make progress '
                    'every day with SkillUp.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openTasks(context),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Manage my tasks'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3157D5),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Your workspace',
              style: TextStyle(
                color: Color(0xFF172B4D),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            // Workspace cards
            Row(
              children: [
                Expanded(
                  child: _featureCard(
                    icon: Icons.checklist_rounded,
                    title: 'My Tasks',
                    description: 'Organize your daily goals',
                    color: const Color(0xFF3157D5),
                    onTap: () => _openTasks(context),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _featureCard(
                    icon: Icons.psychology_alt_rounded,
                    title: 'My Skills',
                    description: 'Track your progress',
                    color: const Color(0xFF159A82),
                    onTap: () {
                      _showComingSoon(context, 'My Skills');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _featureCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Career',
                    description: 'Track your applications',
                    color: const Color(0xFFDB8B25),
                    onTap: () {
                      _showComingSoon(
                        context,
                        'My Applications',
                      );
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _featureCard(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    description: 'Manage your account',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      _showComingSoon(context, 'My Profile');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tip card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE8ECF5),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFDB8B25),
                    size: 28,
                  ),

                  SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A simple tip',
                          style: TextStyle(
                            color: Color(0xFF172B4D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Choose one realistic goal each day. '
                          'Consistent progress is more useful '
                          'than trying to do everything at once.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'SkillUp • Your personal growth companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTasks(context),
        backgroundColor: const Color(0xFF3157D5),
        foregroundColor: Colors.white,
        tooltip: 'Open tasks',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF172B4D),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8ECF5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
