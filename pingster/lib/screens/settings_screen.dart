import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: PingsterTheme.primary200)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: PingsterTheme.primary200,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildSectionHeader('App Settings'),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeColor: PingsterTheme.primary200,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            trailing: Switch(
              value: true, // TODO: Get actual notification settings
              onChanged: (bool value) {
                // TODO: Implement notification settings
              },
              activeColor: PingsterTheme.primary200,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.volume_up,
            title: 'Sound Effects',
            trailing: Switch(
              value: true, // TODO: Get actual sound settings
              onChanged: (bool value) {
                // TODO: Implement sound settings
              },
              activeColor: PingsterTheme.primary200,
            ),
          ),
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Privacy',
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Security',
            onTap: () {
              // TODO: Navigate to security settings
            },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English (US)',
            onTap: () {
              // TODO: Navigate to language settings
            },
          ),
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              // TODO: Navigate to help center
            },
          ),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: 'Report a Bug',
            onTap: () {
              // TODO: Navigate to bug report screen
            },
          ),
          _buildSettingsTile(
            icon: Icons.rate_review,
            title: 'Rate the App',
            onTap: () {
              // TODO: Open app store rating
            },
          ),
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
          _buildSettingsTile(
            icon: Icons.policy,
            title: 'Terms of Service',
            onTap: () {
              // TODO: Navigate to terms of service
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: PingsterTheme.primary200),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}
