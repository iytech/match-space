import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../core/utils/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = StorageService();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;
  String? _avatarUrl;
  AccountType _accountType = AccountType.seeker;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _name = TextEditingController(text: p?.fullName ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _avatarUrl = p?.avatarUrl;
    _accountType = p?.accountType ?? AccountType.seeker;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final f = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 600);
    if (f == null) return;
    setState(() => _busy = true);
    final bytes = await f.readAsBytes();
    final url = await _storage.uploadAvatar(
        bytes: bytes, contentType: f.mimeType ?? 'image/png');
    setState(() {
      _avatarUrl = url;
      _busy = false;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final updated = auth.profile!.copyWith(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      avatarUrl: _avatarUrl,
      accountType: _accountType,
    );
    await auth.saveProfile(updated);
    setState(() => _busy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.terracottaSoft,
                    backgroundImage: (_avatarUrl != null &&
                            _avatarUrl!.isNotEmpty)
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? Text(
                            initialOf(p?.fullName),
                            style: const TextStyle(
                                fontSize: 32,
                                color: AppColors.terracottaDark,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _busy ? null : _pickAvatar,
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.terracotta,
                        child: Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (p?.email != null)
                Center(
                  child: Text(p!.email!,
                      style: const TextStyle(color: AppColors.inkSoft)),
                ),
              if (p?.isPremium ?? false)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.ochre,
                          AppColors.terracotta
                        ]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Premium member',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Account type',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft)),
              ),
              const SizedBox(height: 8),
              ...AccountType.values.map((type) {
                final isSel = type == _accountType;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _accountType = type),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.terracottaSoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSel ? AppColors.terracotta : AppColors.border,
                          width: isSel ? 1.6 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppOptions.accountTypeLabels[type]!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isSel
                                          ? AppColors.terracottaDark
                                          : AppColors.ink)),
                              Text(AppOptions.accountTypeDescriptions[type]!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Icon(
                          isSel
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isSel
                              ? AppColors.terracotta
                              : AppColors.inkFaint,
                        ),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save changes'),
              ),
              const SizedBox(height: 12),
              if (!(p?.isPremium ?? false))
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/subscription'),
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Upgrade to Premium'),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                icon: const Icon(Icons.logout, color: AppColors.ruby),
                label: const Text('Sign out',
                    style: TextStyle(color: AppColors.ruby)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
