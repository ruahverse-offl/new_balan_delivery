import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart' as authSvc;
import '../services/users_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _tabIndex = 2;

  // Profile fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;
  bool _confirmOpen = false;
  final _accountPwCtrl = TextEditingController();

  // Password change
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _pwBusy = false;

  // Notification toggle
  bool _notifSaving = false;

  @override
  void initState() {
    super.initState();
    // Re-fill fields when tab regains focus (e.g. after update from another screen).
    tabIndexNotifier.addListener(_onTabChange);
    _fillFromUser();
  }

  void _onTabChange() {
    if (tabIndexNotifier.value == _tabIndex) {
      _fillFromUser();
    }
  }

  void _fillFromUser() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = (user.mobileNumber ?? '')
        .replaceAll(RegExp(r'\D'), '');
  }

  @override
  void dispose() {
    tabIndexNotifier.removeListener(_onTabChange);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _accountPwCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  bool _hasEdits() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return false;
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final origPhone = (user.mobileNumber ?? '').replaceAll(RegExp(r'\D'), '');
    return _nameCtrl.text.trim() != (user.name).trim() ||
        _emailCtrl.text.trim() != (user.email).trim() ||
        digits != origPhone;
  }

  void _onRequestSave() {
    if (!_hasEdits()) {
      _alert('No changes', 'Update your details before saving.');
      return;
    }
    _accountPwCtrl.clear();
    setState(() => _confirmOpen = true);
  }

  Future<void> _onConfirmSave() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || auth.token == null) return;
    if (_accountPwCtrl.text.trim().isEmpty) {
      _alert('Password required',
          'Enter your account password to save changes.');
      return;
    }
    setState(() => _saving = true);
    try {
      await authSvc.verifyCurrentPassword(
          user.email.trim(), _accountPwCtrl.text);
      final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      await updateUserProfile(
        user.id,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        mobileNumber: digits.length >= 10 ? digits.substring(digits.length - 10) : null,
      );
      await auth.updateLocalUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        mobileNumber: digits.length >= 10
            ? digits.substring(digits.length - 10)
            : user.mobileNumber,
      );
      if (mounted) {
        setState(() => _confirmOpen = false);
        _accountPwCtrl.clear();
        _alert('Saved', 'Your profile was updated.');
      }
    } catch (e) {
      if (mounted) {
        _alert('Could not save',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onChangePassword() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    if (_currentPwCtrl.text.trim().isEmpty) {
      _alert('Validation', 'Enter your current password.');
      return;
    }
    if (_newPwCtrl.text.length < 6) {
      _alert('Validation', 'New password must be at least 6 characters.');
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _alert('Validation', 'New passwords do not match.');
      return;
    }
    setState(() => _pwBusy = true);
    try {
      await authSvc.changePassword(
          auth.token!, _currentPwCtrl.text, _newPwCtrl.text);
      if (mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        _alert('Updated', 'Your password was changed.');
      }
    } catch (e) {
      if (mounted) {
        _alert('Could not update',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _pwBusy = false);
    }
  }

  Future<void> _onToggleNotif(bool next) async {
    if (_notifSaving) return;
    setState(() => _notifSaving = true);
    try {
      await context.read<NotificationProvider>().setEnabled(next);
    } catch (e) {
      if (mounted) {
        _alert('Settings',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _notifSaving = false);
    }
  }

  void _onSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
            'You will need to sign in again to see deliveries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _alert(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [NotificationHeaderButton()],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _h1('Profile'),
                _sub('Your delivery partner account details.'),

                // ── Push notifications toggle ─────────────────────────
                _card(children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Push notifications',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gray900)),
                            const SizedBox(height: 2),
                            Text(
                              'Get alerts for new assignments and order updates.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: notif.enabled,
                        onChanged: notif.loading || _notifSaving
                            ? null
                            : _onToggleNotif,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ]),

                // ── Profile edit card ─────────────────────────────────
                _card(children: [
                  _label('Full name'),
                  _input(_nameCtrl),
                  _label('Email'),
                  _input(_emailCtrl,
                      type: TextInputType.emailAddress),
                  _label('Mobile (10 digits)'),
                  _input(_phoneCtrl,
                      type: TextInputType.phone),
                  const SizedBox(height: 4),
                  _primaryButton(
                    'Save changes',
                    _saving ? null : _onRequestSave,
                    busy: _saving && !_confirmOpen,
                  ),
                ]),

                // ── Password change ───────────────────────────────────
                _sectionLabel('Security'),
                _card(children: [
                  _label('Current password'),
                  _input(_currentPwCtrl, obscure: true),
                  _label('New password'),
                  _input(_newPwCtrl, obscure: true),
                  _label('Confirm new password'),
                  _input(_confirmPwCtrl, obscure: true),
                  const SizedBox(height: 4),
                  _primaryButton(
                    'Update password',
                    _pwBusy ? null : _onChangePassword,
                    busy: _pwBusy,
                  ),
                ]),

                // ── Sign out ──────────────────────────────────────────
                const SizedBox(height: 8),
                _outlineButton('Sign out', _onSignOut,
                    textColor: AppColors.primaryDark),
              ],
            ),
          ),

          // ── Confirm-with-password modal ───────────────────────────
          if (_confirmOpen) _confirmModal(),
        ],
      ),
    );
  }

  Widget _confirmModal() {
    return GestureDetector(
      onTap: () => setState(() => _confirmOpen = false),
      child: Container(
        color: const Color(0x660F172A),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirm with password',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900)),
                const SizedBox(height: 8),
                const Text(
                    'Enter your current account password to save profile changes.',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.gray600)),
                const SizedBox(height: 12),
                _label('Password'),
                TextField(
                  controller: _accountPwCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() => _confirmOpen = false);
                                _accountPwCtrl.clear();
                              },
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: AppColors.gray300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: AppColors.gray800,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _onConfirmSave,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white))
                            : const Text('Save',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _h1(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900)),
      );

  Widget _sub(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14, color: AppColors.gray600, height: 1.4)),
      );

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 0, 0),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
                letterSpacing: 0.5)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
                letterSpacing: 0.5)),
      );

  Widget _input(
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          autocorrect: false,
          textCapitalization: type == TextInputType.emailAddress ||
                  obscure
              ? TextCapitalization.none
              : TextCapitalization.words,
          decoration: const InputDecoration(),
        ),
      );

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _primaryButton(String label, VoidCallback? onTap,
          {bool busy = false}) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.white))
              : Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      );

  Widget _outlineButton(String label, VoidCallback onTap,
      {Color textColor = AppColors.gray800}) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.gray200),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w700)),
        ),
      );
}
