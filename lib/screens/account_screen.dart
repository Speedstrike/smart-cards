// MIT License
//
// Copyright (c) 2026 Aaryan Karlapalem
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:flutter/cupertino.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _showChangeEmail = false;
  bool _showChangePassword = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearMessages() => setState(() {
    _error = null; _success = null;
  });

  Future<void> _submit() async {
    _clearMessages();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = Constants.errorEmptyCredentials);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final res = await _supabase.auth.signUp(email: email, password: password);
        _emailController.clear();
        _passwordController.clear();
        setState(() => _success = res.session != null? Constants.successAccountCreated : Constants.successConfirmEmail);
      }
      else {
        await _supabase.auth.signInWithPassword(email: email, password: password);
        _emailController.clear();
        _passwordController.clear();
        setState(() => _success = Constants.successWelcomeBack);
      }
    }
    on AuthException catch (e) {
      setState(() => _error = e.message);
    }
    catch (_) {
      setState(() => _error = Constants.errorGeneric);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    _clearMessages();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = Constants.errorEmptyEmailReset);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      setState(() => _success = Constants.successPasswordResetSent);
    }
    on AuthException catch (e) {
      setState(() => _error = e.message);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeEmail() async {
    _clearMessages();
    final email = _newEmailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = Constants.errorEmptyNewEmail);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(email: email));
      _newEmailController.clear();
      setState(() {
        _showChangeEmail = false;
        _success = 'Confirmation sent to $email.';
      });
    }
    on AuthException catch (e) {
      setState(() => _error = e.message);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    _clearMessages();
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = Constants.errorEmptyPasswordFields);
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = Constants.errorPasswordMismatch);
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = Constants.errorPasswordLength);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPass));
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _showChangePassword = false;
        _success = Constants.successPasswordUpdated;
      });
    }
    on AuthException catch (e) {
      setState(() => _error = e.message);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    _clearMessages();
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signOut();
    }
    on AuthException catch (e) {
      setState(() => _error = e.message);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(Constants.accountDeleteDialogTitle),
        content: const Text(Constants.accountDeleteDialogContent),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Constants.accountDeleteButtonText)
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Constants.accountCancelButtonText)
          )
        ]
      )
    );
    if (confirmed != true) return;
    _clearMessages();
    setState(() => _isLoading = true);
    try {
      await _supabase.functions.invoke('delete-user');
      await _supabase.auth.signOut();
    }
    catch (_) {
      setState(() => _error = Constants.errorDeleteAccount);
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(TextEditingController controller, String placeholder, {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Constants.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.border, width: 1)
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 15),
        style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        obscureText: obscure,
        keyboardType: keyboard,
        autocorrect: false,
        decoration: null
      )
    );
  }

  Widget _managementRow(String label, IconData icon, VoidCallback onTap, {bool destructive = false, bool isExpanded = false, bool hasDropdown = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Constants.cardBackground,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: destructive? CupertinoColors.systemRed.withValues(alpha: 0.1) : CupertinoColors.activeBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Icon(
                icon,
                size: 20,
                color: destructive? CupertinoColors.systemRed : CupertinoColors.activeBlue
              )
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: destructive? CupertinoColors.systemRed : CupertinoColors.white,
                  fontWeight: FontWeight.w400
                )
              )
            ),
            Icon(
              hasDropdown? (isExpanded? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right) : CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey2
            )
          ]
        )
      )
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed, {bool isFilled = true}) {
    if (isFilled) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white
            )
          )
        )
      );
    }
    else {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.activeBlue
          )
        )
      );
    }
  }

  Widget _messageBanner(String message, Color baseColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1)
      ),
      child: Row(
        children: [
          Icon(
            baseColor == CupertinoColors.systemRed? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.checkmark_circle_fill,
            color: baseColor,
            size: 20
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.w500)
            )
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return CupertinoPageScaffold(
      backgroundColor: Constants.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Constants.background.withValues(alpha: 0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chevron_back, color: CupertinoColors.activeBlue, size: 24),
              Text(Constants.accountButtonBack, style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 17))
            ]
          )
        )
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const SizedBox(height: 8),
            Text(
              user == null? (_isSignUp? Constants.accountButtonSignUp : Constants.accountWelcomeTitle) : Constants.accountSettingsTitle,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: CupertinoColors.white, letterSpacing: -0.5)
            ),
            const SizedBox(height: 6),
            Text(
              user == null? (_isSignUp? Constants.accountCreateSubtitle : Constants.accountWelcomeSubtitle) : user.email ?? '',
              style: TextStyle(fontSize: 16, color: user == null? CupertinoColors.systemGrey : CupertinoColors.activeBlue, fontWeight: user == null? FontWeight.w400 : FontWeight.w500)
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              _messageBanner(_error!, CupertinoColors.systemRed),
              const SizedBox(height: 20)
            ],
            if (_success != null) ...[
              _messageBanner(_success!, CupertinoColors.systemGreen),
              const SizedBox(height: 20)
            ],
            if (user == null) ...[
              _field(_emailController, Constants.accountPlaceholderEmail, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _field(_passwordController, Constants.accountPlaceholderPassword, obscure: true),
              const SizedBox(height: 24),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CupertinoActivityIndicator(radius: 14))
                )
              else ...[
                _actionButton(_isSignUp? Constants.accountButtonSignUp : Constants.accountButtonSignIn, _submit),
                if (!_isSignUp) ...[
                  const SizedBox(height: 15),
                  Center(
                    child: GestureDetector(
                      onTap: _resetPassword,
                      child: const Text(
                        Constants.accountForgotPassword,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w400
                        )
                      )
                    )
                  )
                ],
                Center(
                  child: _actionButton(
                    _isSignUp? Constants.accountButtonToggleToSignIn : Constants.accountButtonToggleToSignUp,
                    () => setState(() {
                      _isSignUp = !_isSignUp;
                      _clearMessages();
                    }),
                    isFilled: false
                  )
                )
              ]
            ]
            else if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CupertinoActivityIndicator(radius: 14))
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Constants.cardBackground,
                  child: Column(
                    children: [
                      _managementRow(
                        Constants.accountRowChangeEmail, 
                        CupertinoIcons.mail, 
                        () => setState(() {
                          _showChangeEmail = !_showChangeEmail;
                          _showChangePassword = false;
                          _clearMessages();
                        }),
                        isExpanded: _showChangeEmail
                      ),
                      if (_showChangeEmail)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Constants.cardSubBackground,
                          child: Column(
                            children: [
                              _field(_newEmailController, Constants.accountPlaceholderNewEmail, keyboard: TextInputType.emailAddress),
                              const SizedBox(height: 14),
                              _actionButton(Constants.accountButtonUpdateEmail, _changeEmail)
                            ]
                          )
                        ),
                      if (!_showChangeEmail)
                        Container(height: 0.5, color: Constants.border, margin: const EdgeInsets.only(left: 54)),
                      _managementRow(
                        Constants.accountRowChangePassword, 
                        CupertinoIcons.lock, 
                        () => setState(() {
                          _showChangePassword = !_showChangePassword;
                          _showChangeEmail = false;
                          _clearMessages();
                        }),
                        isExpanded: _showChangePassword
                      ),
                      if (_showChangePassword)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Constants.cardSubBackground,
                          child: Column(
                            children: [
                              _field(_newPasswordController, Constants.accountPlaceholderNewPassword, obscure: true),
                              const SizedBox(height: 12),
                              _field(_confirmPasswordController, Constants.accountPlaceholderConfirmPassword, obscure: true),
                              const SizedBox(height: 14),
                              _actionButton(Constants.accountButtonUpdatePassword, _changePassword)
                            ]
                          )
                        ),
                      if (!_showChangePassword)
                        Container(height: 0.5, color: Constants.border, margin: const EdgeInsets.only(left: 54)),
                      _managementRow(Constants.accountRowSignOut, CupertinoIcons.square_arrow_right, _signOut, hasDropdown: false)
                    ]
                  )
                )
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Constants.cardBackground,
                  child: _managementRow(Constants.accountRowDeleteAccount, CupertinoIcons.trash, _deleteAccount, destructive: true, hasDropdown: false)
                )
              )
            ]
          ]
        )
      )
    );
  }
}