import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_application_1/core/config.dart';
import 'package:flutter_application_1/core/format.dart';
import 'package:flutter_application_1/feat/transaction/transaction_service.dart'
    show apiDate;
import 'package:flutter_application_1/feat/user/user_service.dart';
import 'package:flutter_application_1/widgets/app_page_header.dart';
import 'package:flutter_application_1/widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(
    text: widget.profile['fullName'] as String? ?? '',
  );
  late final _username = TextEditingController(
    text: widget.profile['username'] as String? ?? '',
  );
  late final _email = TextEditingController(
    text: widget.profile['email'] as String? ?? '',
  );
  late final _age = TextEditingController(
    text: widget.profile['age']?.toString() ?? '',
  );
  late String _gender = widget.profile['gender'] as String? ?? 'unknown';
  String? _avatar;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _avatar = StorageConfig.avatarUrl(widget.profile['avatar'] as String?);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await UserService.updateProfile(
        fullName: _fullName.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        gender: _gender,
        age: _age.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final initial = parseApiDate(_age.text) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _age.text = apiDate(picked));
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final profile = await UserService.uploadAvatar(file);
      if (!mounted) return;
      setState(() {
        _avatar = StorageConfig.avatarUrl(profile['avatar'] as String?);
        widget.profile['avatar'] = profile['avatar'];
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile['fullName'] as String? ?? 'DompetIQ';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Edit Profile'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _uploadingAvatar ? null : _pickAvatar,
                          child: Stack(
                            children: [
                              ProfileAvatar(
                                imageUrl: _avatar,
                                name: name,
                                radius: 36,
                                backgroundColor: Colors.white,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF101010),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _uploadingAvatar
                                      ? const Padding(
                                          padding: EdgeInsets.all(7),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          PhosphorIconsRegular.camera,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF101828),
                        ),
                      ),
                      Text(
                        '@${widget.profile['username'] ?? ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Divider(color: Color(0xFFE4E7EC), height: 1),
                      const SizedBox(height: 22),
                      _field(
                        'Full name',
                        _fullName,
                        validator: (value) => _required(value, 'Full name'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _genderField()),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              'Birth date',
                              _age,
                              readOnly: true,
                              muted: false,
                              suffixIcon: const Icon(
                                PhosphorIconsRegular.calendar,
                                size: 18,
                                color: Color(0xFF3B62FF),
                              ),
                              onTap: _pickBirthDate,
                              validator: _birthDateValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Email',
                        _email,
                        keyboard: TextInputType.emailAddress,
                        readOnly: true,
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Username',
                        _username,
                        readOnly: true,
                        validator: _usernameValidator,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _saving || _uploadingAvatar ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B62FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool? muted,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    final isMuted = muted ?? readOnly;
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        color: isMuted ? const Color(0xFF98A2B3) : const Color(0xFF101828),
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: isMuted,
        fillColor: isMuted ? const Color(0xFFF2F4F7) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _genderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      validator: (value) => value == null ? 'Gender is required' : null,
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _gender = value);
      },
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (value.trim().length < 2) return '$label is too short';
    return null;
  }

  String? _usernameValidator(String? value) {
    final error = _required(value, 'Username');
    if (error != null) return error;
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value!.trim())) {
      return 'Username contains invalid characters';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final error = _required(value, 'Email');
    if (error != null) return error;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _birthDateValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Birth date is required';
    if (parseApiDate(value) == null) return 'Use MM-DD-YYYY format';
    return null;
  }
}
