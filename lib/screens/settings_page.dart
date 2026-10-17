
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_theme.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  bool _notifications = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  bool _jobSearch = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  User? get _user => _supabase.auth.currentUser;

  Map<String, dynamic> get _metadata =>
      Map<String, dynamic>.from(_user?.userMetadata ?? {});

  String get _name {
    final value = _metadata['nom']?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
    final email = _user?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Étudiant';
  }

  String get _email => _user?.email ?? 'E-mail indisponible';

  String get _phone =>
      _metadata['telephone']?.toString() ?? '';

  String get _school =>
      _metadata['etablissement']?.toString() ?? '';

  String get _formation =>
      _metadata['formation']?.toString() ?? '';

  String get _year =>
      _metadata['annee_etude']?.toString() ?? '';

  String get _photoUrl =>
      _metadata['photo_url']?.toString() ?? '';

  @override
  void initState() {
    super.initState();

    final data = _metadata;
    _notifications = data['notifications_enabled'] != false;
    _emailNotifications = data['email_notifications'] != false;
    _darkMode = data['dark_mode'] == true;
    _jobSearch = data['recherche_active'] != false;

    appThemeMode.value =
        _darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _saveMetadata(
    Map<String, dynamic> updates,
  ) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        data: {..._metadata, ...updates},
      ),
    );
  }

  Future<void> _togglePreference(
    String key,
    bool value,
  ) async {
    final previous = _metadata[key];

    setState(() {
      switch (key) {
        case 'notifications_enabled':
          _notifications = value;
          break;
        case 'email_notifications':
          _emailNotifications = value;
          break;
        case 'dark_mode':
          _darkMode = value;
          break;
        case 'recherche_active':
          _jobSearch = value;
          break;
      }
    });

    if (key == 'dark_mode') {
      appThemeMode.value =
          value ? ThemeMode.dark : ThemeMode.light;
    }

    try {
      await _saveMetadata({key: value});
      if (!mounted) return;
      _message('Préférence enregistrée.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        switch (key) {
          case 'notifications_enabled':
            _notifications = previous != false;
            break;
          case 'email_notifications':
            _emailNotifications = previous != false;
            break;
          case 'dark_mode':
            _darkMode = previous == true;
            break;
          case 'recherche_active':
            _jobSearch = previous != false;
            break;
        }
      });

      if (key == 'dark_mode') {
        appThemeMode.value =
            _darkMode ? ThemeMode.dark : ThemeMode.light;
      }

      _message('Enregistrement impossible : $e');
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_user == null || _uploadingPhoto) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (image == null || !mounted) return;

      setState(() => _uploadingPhoto = true);

      final Uint8List bytes = await image.readAsBytes();
      final userId = _user!.id;

      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';

      const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Format non accepté. Choisis JPG, PNG ou WEBP.');
      }

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final path = '$userId/avatar.$extension';

      await _supabase.storage
          .from('profile-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final publicUrl = _supabase.storage
          .from('profile-photos')
          .getPublicUrl(path);

      await _saveMetadata({'photo_url': publicUrl});

      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _message('Photo de profil mise à jour.');
    } on StorageException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _message('Erreur Storage : ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _message('Impossible de modifier la photo : $e');
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final schoolController = TextEditingController(text: _school);
    final formationController = TextEditingController(text: _formation);
    final yearController = TextEditingController(text: _year);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier mon profil'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formField(
                    nameController,
                    'Nom complet',
                    Icons.person_outline,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    phoneController,
                    'Téléphone',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    schoolController,
                    'Établissement',
                    Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    formationController,
                    'Formation',
                    Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    yearController,
                    'Année d’études',
                    Icons.calendar_month_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _saving = true);

      try {
        await _saveMetadata({
          'nom': nameController.text.trim(),
          'telephone': phoneController.text.trim(),
          'etablissement': schoolController.text.trim(),
          'formation': formationController.text.trim(),
          'annee_etude': yearController.text.trim(),
        });

        if (!mounted) return;
        setState(() => _saving = false);
        _message('Profil mis à jour.');
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        _message('Impossible d’enregistrer le profil : $e');
      }
    }

    nameController.dispose();
    phoneController.dispose();
    schoolController.dispose();
    formationController.dispose();
    yearController.dispose();
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: skillUpPrimary),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'Ce champ est obligatoire.'
              : null
          : null,
    );
  }

  Future<void> _changePassword() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      _message('Aucune adresse e-mail associée au compte.');
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _message('Si la demande est acceptée, un lien sera envoyé à $email.');
    } on AuthException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Demande impossible : $e');
    }
  }

  void _showEmail() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adresse e-mail'),
        content: SelectableText(_email),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'SkillUp',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.school_rounded,
        color: skillUpPrimary,
        size: 36,
      ),
      children: const [
        Text(
          'SkillUp vous aide à organiser vos tâches, '
          'développer vos compétences et préparer votre carrière.',
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Voulez-vous vraiment fermer votre session ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC4545),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _supabase.auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _message('Déconnexion impossible : $e');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, {Color? color}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: (color ?? skillUpPrimary).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color ?? skillUpPrimary,
        size: 21,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool last = false,
    Color? iconColor,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          leading: _iconBox(icon, color: iconColor),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
        if (!last)
          const Divider(height: 1, indent: 70, endIndent: 14),
      ],
    );
  }

  Widget _preferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'S';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon profil & réglages',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'À propos de SkillUp',
            onPressed: _about,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Text(
              'Gérez votre compte et vos préférences.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // CARTE PROFIL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 39,
                              backgroundColor: const Color(0xFFE5E7FF),
                              backgroundImage: _photoUrl.isNotEmpty
                                  ? NetworkImage(_photoUrl)
                                  : null,
                              onBackgroundImageError: _photoUrl.isNotEmpty
                                  ? (exception, stackTrace) {}
                                  : null,
                              child: _photoUrl.isEmpty
                                  ? Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        color: skillUpPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Material(
                                color: skillUpPrimary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _uploadingPhoto
                                      ? null
                                      : _pickAndUploadPhoto,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 17,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formation.isEmpty
                                    ? 'Formation non renseignée'
                                    : _formation,
                                style: const TextStyle(
                                  color: skillUpPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _school.isEmpty
                                    ? 'Établissement non renseigné'
                                    : _school,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_year.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _tag(_year),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _editProfile,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Modifier le profil'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: 'Changer la photo',
                          onPressed: _uploadingPhoto
                              ? null
                              : _pickAndUploadPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                        ),
                      ],
                    ),
                    if (_saving) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle('Opportunités & candidatures'),
            const SizedBox(height: 10),
            _card([
              _preferenceSwitch(
                icon: Icons.work_outline_rounded,
                title: 'Recherche active de stage',
                subtitle: 'Indiquez si vous recherchez un stage ou un PFE.',
                value: _jobSearch,
                onChanged: (value) =>
                    _togglePreference('recherche_active', value),
              ),
            ]),

            const SizedBox(height: 24),

            _sectionTitle('Compte & sécurité'),
            const SizedBox(height: 10),
            _card([
              _tile(
                icon: Icons.person_outline_rounded,
                title: 'Informations personnelles',
                subtitle: 'Nom, téléphone, formation et établissement',
                onTap: _editProfile,
              ),
              _tile(
                icon: Icons.email_outlined,
                title: 'Adresse e-mail',
                subtitle: _email,
                onTap: _showEmail,
              ),
              _tile(
                icon: Icons.lock_outline_rounded,
                title: 'Mot de passe',
                subtitle: 'Recevoir un lien de réinitialisation',
                onTap: _changePassword,
                last: true,
              ),
            ]),

            const SizedBox(height: 24),

            _sectionTitle('Préférences'),
            const SizedBox(height: 10),
            _card([
              _preferenceSwitch(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Autoriser les notifications dans les préférences',
                value: _notifications,
                onChanged: (value) =>
                    _togglePreference('notifications_enabled', value),
              ),
              const Divider(height: 1, indent: 70, endIndent: 14),
              _preferenceSwitch(
                icon: Icons.mark_email_unread_outlined,
                title: 'Mises à jour par e-mail',
                subtitle: 'Préférence de réception des e-mails',
                value: _emailNotifications,
                onChanged: (value) =>
                    _togglePreference('email_notifications', value),
              ),
              const Divider(height: 1, indent: 70, endIndent: 14),
              _preferenceSwitch(
                icon: Icons.dark_mode_outlined,
                title: 'Mode sombre',
                subtitle: 'Appliquer le thème à toute l’application',
                value: _darkMode,
                onChanged: (value) =>
                    _togglePreference('dark_mode', value),
              ),
            ]),

            const SizedBox(height: 24),

            _sectionTitle('Support & informations'),
            const SizedBox(height: 10),
            _card([
              _tile(
                icon: Icons.help_outline_rounded,
                title: 'À propos de SkillUp',
                subtitle: 'Informations sur l’application',
                onTap: _about,
                last: true,
              ),
            ]),

            const SizedBox(height: 26),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC4545),
                  side: const BorderSide(color: Color(0xFFF0CACA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            Center(
              child: Text(
                'SKILLUP  •  VERSION 1.0.0',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: skillUpPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: skillUpPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
