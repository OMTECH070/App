import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/device_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final authProvider = context.read<AuthProvider>();
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('settings') ?? 'Settings'),
      ),
      body: ListView(
        children: [
          // Language Section
          _buildSectionHeader(context, loc?.translate('language') ?? 'Language'),
          _buildLanguageTile(
            context,
            'English',
            'en',
            settingsProvider,
            loc,
          ),
          _buildLanguageTile(
            context,
            'हिंदी',
            'hi',
            settingsProvider,
            loc,
          ),
          _buildLanguageTile(
            context,
            'मराठी',
            'mr',
            settingsProvider,
            loc,
          ),

          const Divider(),

          // Display Section
          _buildSectionHeader(context, 'Display'),
          ListTile(
            title: Text(loc?.translate('dark_mode') ?? 'Dark Mode'),
            trailing: Switch(
              value: settingsProvider.darkMode,
              onChanged: (value) {
                settingsProvider.setDarkMode(value);
              },
            ),
          ),

          const Divider(),

          // Device Management Section
          _buildSectionHeader(context, loc?.translate('device_list') ?? 'Device Management'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Paired Devices (${deviceProvider.devices.length})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (deviceProvider.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No devices paired',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...deviceProvider.devices.map((device) {
              return ListTile(
                title: Text(device['field_name'] ?? 'Unknown'),
                subtitle: Text(device['device_id'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed('/device_control');
                },
              );
            }).toList(),

          const Divider(),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          ListTile(
            title: Text(loc?.translate('sign_out') ?? 'Sign Out'),
            trailing: const Icon(Icons.logout),
            onTap: () => _showSignOutDialog(context, authProvider, loc),
          ),

          const SizedBox(height: 24),

          // App Version
          Center(
            child: Text(
              'AI Smart Farming Assist v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String? title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title ?? '',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String displayName,
    String languageCode,
    SettingsProvider settingsProvider,
    AppLocalizations? loc,
  ) {
    final isSelected = settingsProvider.language == languageCode;

    return ListTile(
      title: Text(displayName),
      leading: Radio<String>(
        value: languageCode,
        groupValue: settingsProvider.language,
        onChanged: (value) {
          if (value != null) {
            settingsProvider.setLanguage(value);
          }
        },
      ),
      onTap: () {
        settingsProvider.setLanguage(languageCode);
      },
    );
  }

  void _showSignOutDialog(
      BuildContext context, AuthProvider authProvider, AppLocalizations? loc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc?.translate('sign_out') ?? 'Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                authProvider.logout();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(loc?.translate('sign_out') ?? 'Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
