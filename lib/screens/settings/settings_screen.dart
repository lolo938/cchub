import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/services/logger_service.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _appointmentReminders = true;
  bool _marketingEmails = false;
  bool _biometricAuth = false;
  bool _autoBackup = true;
  bool _dataSync = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  String _selectedCurrency = 'INR';
  String _selectedTimeFormat = '12 Hour';

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Malayalam'
  ];
  final List<String> _themes = ['Light', 'Dark', 'System'];
  final List<String> _currencies = ['INR', 'USD', 'EUR'];
  final List<String> _timeFormats = ['12 Hour', '24 Hour'];

  @override
  void initState() {
    super.initState();
    LoggerService.userAction('settings_screen_opened');
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: Load settings from SharedPreferences or provider
    // For now, using default values
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Notifications Section
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive all app notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    LoggerService.userAction('notifications_toggled',
                        parameters: {'enabled': value});
                  },
                ),
                if (_notificationsEnabled) ...[
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Instant notifications on your device',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'SMS Notifications',
                    subtitle: 'Receive important updates via SMS',
                    value: _smsNotifications,
                    onChanged: (value) {
                      setState(() {
                        _smsNotifications = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Appointment Reminders',
                    subtitle: 'Get reminded about upcoming consultations',
                    value: _appointmentReminders,
                    onChanged: (value) {
                      setState(() {
                        _appointmentReminders = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Marketing Emails',
                    subtitle: 'Receive promotional offers and updates',
                    value: _marketingEmails,
                    onChanged: (value) {
                      setState(() {
                        _marketingEmails = value;
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Security Section
            _buildSectionCard(
              title: 'Security & Privacy',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  title: 'Biometric Authentication',
                  subtitle: 'Use fingerprint or face unlock',
                  value: _biometricAuth,
                  onChanged: (value) {
                    setState(() {
                      _biometricAuth = value;
                    });
                    LoggerService.userAction('biometric_auth_toggled',
                        parameters: {'enabled': value});
                  },
                ),
                _buildActionTile(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  icon: Icons.lock,
                  onTap: _changePassword,
                ),
                _buildActionTile(
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  icon: Icons.privacy_tip,
                  onTap: _viewPrivacyPolicy,
                ),
                _buildActionTile(
                  title: 'Data & Permissions',
                  subtitle: 'Manage app permissions',
                  icon: Icons.admin_panel_settings,
                  onTap: _managePermissions,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preferences Section
            _buildSectionCard(
              title: 'Preferences',
              icon: Icons.tune,
              children: [
                _buildDropdownTile(
                  title: 'Language',
                  subtitle: 'App display language',
                  value: _selectedLanguage,
                  items: _languages,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    LoggerService.userAction('language_changed',
                        parameters: {'language': value});
                  },
                ),
                _buildDropdownTile(
                  title: 'Theme',
                  subtitle: 'App appearance',
                  value: _selectedTheme,
                  items: _themes,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    LoggerService.userAction('theme_changed',
                        parameters: {'theme': value});
                  },
                ),
                _buildDropdownTile(
                  title: 'Currency',
                  subtitle: 'Display currency',
                  value: _selectedCurrency,
                  items: _currencies,
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                ),
                _buildDropdownTile(
                  title: 'Time Format',
                  subtitle: 'Time display format',
                  value: _selectedTimeFormat,
                  items: _timeFormats,
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeFormat = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data & Storage Section
            _buildSectionCard(
              title: 'Data & Storage',
              icon: Icons.storage,
              children: [
                _buildSwitchTile(
                  title: 'Auto Backup',
                  subtitle: 'Automatically backup your data',
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Data Sync',
                  subtitle: 'Sync data across devices',
                  value: _dataSync,
                  onChanged: (value) {
                    setState(() {
                      _dataSync = value;
                    });
                  },
                ),
                _buildActionTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  icon: Icons.cleaning_services,
                  onTap: _clearCache,
                ),
                _buildActionTile(
                  title: 'Export Data',
                  subtitle: 'Download your data',
                  icon: Icons.download,
                  onTap: _exportData,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Support Section
            _buildSectionCard(
              title: 'Support & Feedback',
              icon: Icons.help,
              children: [
                _buildActionTile(
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  icon: Icons.help_center,
                  onTap: _openHelpCenter,
                ),
                _buildActionTile(
                  title: 'Contact Support',
                  subtitle: 'Reach out to our support team',
                  icon: Icons.support_agent,
                  onTap: _contactSupport,
                ),
                _buildActionTile(
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  icon: Icons.feedback,
                  onTap: _sendFeedback,
                ),
                _buildActionTile(
                  title: 'Rate App',
                  subtitle: 'Rate us on the app store',
                  icon: Icons.star_rate,
                  onTap: _rateApp,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About Section
            _buildSectionCard(
              title: 'About',
              icon: Icons.info,
              children: [
                _buildActionTile(
                  title: 'Terms of Service',
                  subtitle: 'View terms and conditions',
                  icon: Icons.description,
                  onTap: _viewTermsOfService,
                ),
                _buildActionTile(
                  title: 'App Version',
                  subtitle: 'Version 1.0.0 (Build 1)',
                  icon: Icons.info_outline,
                  onTap: _showVersionInfo,
                ),
                _buildActionTile(
                  title: 'Licenses',
                  subtitle: 'Open source licenses',
                  icon: Icons.code,
                  onTap: _viewLicenses,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            underline: const SizedBox.shrink(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    LoggerService.userAction('change_password_pressed');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content:
            const Text('This will redirect you to the password change page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to change password screen
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _viewPrivacyPolicy() {
    LoggerService.userAction('privacy_policy_viewed');
    // TODO: Open privacy policy URL or screen
    _showComingSoonDialog('Privacy Policy');
  }

  void _managePermissions() {
    LoggerService.userAction('manage_permissions_pressed');
    // TODO: Open app settings or permissions screen
    _showComingSoonDialog('Data & Permissions');
  }

  void _clearCache() {
    LoggerService.userAction('clear_cache_pressed');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performClearCache();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _performClearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData() {
    LoggerService.userAction('export_data_pressed');
    // TODO: Implement data export
    _showComingSoonDialog('Data Export');
  }

  void _openHelpCenter() {
    LoggerService.userAction('help_center_opened');
    // TODO: Open help center URL or screen
    _showComingSoonDialog('Help Center');
  }

  void _contactSupport() {
    LoggerService.userAction('contact_support_pressed');
    // TODO: Open support contact options
    _showComingSoonDialog('Contact Support');
  }

  void _sendFeedback() {
    LoggerService.userAction('send_feedback_pressed');
    // TODO: Open feedback form
    _showComingSoonDialog('Send Feedback');
  }

  void _rateApp() {
    LoggerService.userAction('rate_app_pressed');
    // TODO: Open app store rating
    _showComingSoonDialog('Rate App');
  }

  void _viewTermsOfService() {
    LoggerService.userAction('terms_of_service_viewed');
    // TODO: Open terms of service URL or screen
    _showComingSoonDialog('Terms of Service');
  }

  void _showVersionInfo() {
    LoggerService.userAction('version_info_viewed');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ChildCare Hub'),
            const SizedBox(height: 8),
            Text('Version: 1.0.0', style: TextStyle(color: Colors.grey[600])),
            Text('Build: 1', style: TextStyle(color: Colors.grey[600])),
            Text('Release Date: 2024',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewLicenses() {
    LoggerService.userAction('licenses_viewed');
    showLicensePage(
      context: context,
      applicationName: 'ChildCare Hub',
      applicationVersion: '1.0.0',
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
