import 'package:flutter/material.dart';
import '../../core/storage_service.dart';
import '../../core/app_theme.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late StorageService _storage;
  bool _isLoading = true;
  
  bool _notificationsEnabled = true;
  String _selectedTheme = 'system';
  String _selectedLanguage = 'uk';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _storage = await StorageService.getInstance();
    
    setState(() {
      _notificationsEnabled = _storage.getNotificationsEnabled();
      _selectedTheme = _storage.getThemeMode();
      _selectedLanguage = _storage.getLanguage();
      _isLoading = false;
    });
  }

  Future<void> _saveNotificationsSetting(bool value) async {
    await _storage.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
            ? 'Сповіщення увімкнено' 
            : 'Сповіщення вимкнено'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveThemeSetting(String theme) async {
    await _storage.setThemeMode(theme);
    setState(() {
      _selectedTheme = theme;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Тема змінена на: ${_getThemeName(theme)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveLanguageSetting(String language) async {
    await _storage.setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Мова змінена на: ${_getLanguageName(language)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Світла';
      case 'dark':
        return 'Темна';
      case 'system':
        return 'Системна';
      default:
        return theme;
    }
  }

  String _getLanguageName(String language) {
    switch (language) {
      case 'uk':
        return 'Українська';
      case 'en':
        return 'English';
      default:
        return language;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Налаштування',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          
          SwitchListTile(
            title: const Text('Сповіщення'),
            subtitle: const Text('Отримувати сповіщення про нові повідомлення'),
            value: _notificationsEnabled,
            onChanged: _saveNotificationsSetting,
            secondary: const Icon(Icons.notifications_outlined),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Тема'),
            subtitle: Text(_getThemeName(_selectedTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Виберіть тему'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('Світла'),
                        value: 'light',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            _saveThemeSetting(value);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Темна'),
                        value: 'dark',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            _saveThemeSetting(value);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Системна'),
                        value: 'system',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            _saveThemeSetting(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Мова'),
            subtitle: Text(_getLanguageName(_selectedLanguage)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Виберіть мову'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('Українська'),
                        value: 'uk',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            _saveLanguageSetting(value);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('English'),
                        value: 'en',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            _saveLanguageSetting(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Налаштування зберігаються локально через SharedPreferences',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

