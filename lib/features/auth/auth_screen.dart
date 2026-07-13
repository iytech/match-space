import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  AccountType _accountType = AccountType.seeker;
  bool _busy = false;
  String? _error;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final err = _isLogin
        ? await auth.signIn(_email.text.trim(), _password.text)
        : await auth.signUp(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            accountType: _accountType,
          );
    if (mounted) {
      setState(() {
        _busy = false;
        _error = err;
      });
      // On success, replace the stack with home so the user leaves both the
      // auth screen and the intro (which sits underneath when reached from it).
      if (err == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    }
  }

  Widget _panelTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left: brand panel (hidden on narrow screens)
          if (MediaQuery.of(context).size.width > 880)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.slate900, AppColors.terracottaDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Nigeria\u2019s property',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 22)),
                      const SizedBox(height: 6),
                      const Text('marketplace',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              height: 1.05)),
                      const SizedBox(height: 18),
                      const SizedBox(
                        width: 400,
                        child: Text(
                          'Buy, rent, lease, or list property with confidence. '
                          'Seekers find verified homes and land and message '
                          'owners directly; owners and agents reach serious '
                          'buyers, manage listings, and book viewings \u2014 '
                          'all in one place.',
                          style: TextStyle(
                              color: Colors.white60, height: 1.6, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          _panelTag('Verified listings'),
                          const SizedBox(width: 10),
                          _panelTag('Direct chat'),
                          const SizedBox(width: 10),
                          _panelTag('Book viewings'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Right: form
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: AppLogo(size: 32)),
                        const SizedBox(height: 36),
                        Text(_isLogin ? 'Sign in' : 'Create your account',
                            style:
                                Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 8),
                        Text(
                            _isLogin
                                ? 'Sign in to continue browsing and messaging.'
                                : 'Join to save homes, message owners, and list properties.',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 28),
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _name,
                            decoration:
                                const InputDecoration(hintText: 'Full name'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          const Text('I am a…',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.inkSoft)),
                          const SizedBox(height: 8),
                          _AccountTypeSelector(
                            selected: _accountType,
                            onChanged: (t) =>
                                setState(() => _accountType = t),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(hintText: 'Email address'),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration:
                              const InputDecoration(hintText: 'Password'),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'At least 6 characters'
                              : null,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                hintText: 'Phone (optional)'),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.ruby.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.ruby, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AppColors.ruby,
                                          fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_isLogin ? 'Sign in' : 'Create account'),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _isLogin = !_isLogin),
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: _isLogin
                                      ? "New here? "
                                      : 'Already have an account? ',
                                  style: const TextStyle(
                                      color: AppColors.inkSoft)),
                              TextSpan(
                                  text: _isLogin ? 'Create account' : 'Sign in',
                                  style: const TextStyle(
                                      color: AppColors.terracotta,
                                      fontWeight: FontWeight.w700)),
                            ])),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable account-type picker shown during sign-up. Seeker / Owner / Agent.
class _AccountTypeSelector extends StatelessWidget {
  final AccountType selected;
  final ValueChanged<AccountType> onChanged;
  const _AccountTypeSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AccountType.values.map((type) {
        final isSel = type == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(type),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? AppColors.terracottaSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel ? AppColors.terracotta : AppColors.border,
                  width: isSel ? 1.6 : 1,
                ),
              ),
              child: Row(children: [
                Icon(
                  _iconFor(type),
                  size: 22,
                  color: isSel ? AppColors.terracotta : AppColors.inkSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppOptions.accountTypeLabels[type]!,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSel
                                  ? AppColors.terracottaDark
                                  : AppColors.ink)),
                      Text(AppOptions.accountTypeDescriptions[type]!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                Icon(
                  isSel
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSel ? AppColors.terracotta : AppColors.inkFaint,
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(AccountType t) {
    switch (t) {
      case AccountType.seeker:
        return Icons.search_rounded;
      case AccountType.owner:
        return Icons.home_rounded;
      case AccountType.agent:
        return Icons.badge_rounded;
    }
  }
}
