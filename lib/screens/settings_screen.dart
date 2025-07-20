import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'ar';
  String _selectedTheme = 'system';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            const SizedBox(height: 24),

            // General Settings
            _buildGeneralSettings(),
            const SizedBox(height: 24),

            // App Settings
            _buildAppSettings(),
            const SizedBox(height: 24),

            // Security Settings
            _buildSecuritySettings(),
            const SizedBox(height: 24),

            // About Section
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userData;
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1976D2),
                  child: user?.profileImage != null
                      ? ClipOval(
                          child: Image.network(
                            user!.profileImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'مستخدم',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user?.getRoleName('ar') ?? 'مستخدم',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfileDialog(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'الإعدادات العامة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة'),
            subtitle: Text(_selectedLanguage == 'ar' ? 'العربية' : 'English'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showLanguageDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('المظهر'),
            subtitle: Text(_getThemeName(_selectedTheme)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('الإشعارات'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'إعدادات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('النسخ الاحتياطي'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showBackupDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('استعادة البيانات'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showRestoreDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('مسح ذاكرة التخزين المؤقت'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _clearCache(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'إعدادات الأمان',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('تغيير كلمة المرور'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('المصادقة الثنائية'),
            trailing: Switch(value: false, onChanged: (value) {}),
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('الأجهزة المتصلة'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showDevicesDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'حول التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('إصدار التطبيق'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showVersionInfo(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showTermsOfService(),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('المساعدة والدعم'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showHelpSupport(),
          ),
        ],
      ),
    );
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'فاتح';
      case 'dark':
        return 'داكن';
      case 'system':
        return 'حسب النظام';
      default:
        return 'حسب النظام';
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'الاسم')),
            TextField(
              decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث الملف الشخصي')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              leading: Radio<String>(
                value: 'ar',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('فاتح'),
              leading: Radio<String>(
                value: 'light',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('داكن'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('حسب النظام'),
              leading: Radio<String>(
                value: 'system',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'كلمة المرور الحالية'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'كلمة المرور الجديدة'),
              obscureText: true,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور الجديدة',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تغيير كلمة المرور')),
              );
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('النسخ الاحتياطي'),
        content: const Text('هل تريد إنشاء نسخة احتياطية من البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية')),
              );
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة البيانات'),
        content: const Text('هل تريد استعادة البيانات من النسخة الاحتياطية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم استعادة البيانات')),
              );
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم مسح ذاكرة التخزين المؤقت')),
    );
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الأجهزة المتصلة'),
        content: const Text('لا توجد أجهزة متصلة حالياً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات الإصدار'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إصدار التطبيق: 1.0.0'),
            Text('تاريخ الإصدار: يناير 2024'),
            Text('المطور: فريق سوريا للتراث'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('سياسة الخصوصية')));
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('شروط الاستخدام')));
  }

  void _showHelpSupport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('المساعدة والدعم')));
  }
}
