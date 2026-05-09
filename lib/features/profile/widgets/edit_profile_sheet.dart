import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';

/// Shows the edit profile bottom sheet.
/// Returns the updated [UserModel] if the user saved, or null if dismissed.
Future<UserModel?> showEditProfileSheet(
    BuildContext context,
    UserModel user,
    ) {
  return showModalBottomSheet<UserModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _quoteCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.displayName);
    _bioCtrl   = TextEditingController(text: widget.user.bio);
    _quoteCtrl = TextEditingController(text: widget.user.pinnedQuote);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final name  = _nameCtrl.text.trim();
    final bio   = _bioCtrl.text.trim();
    final quote = _quoteCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Display name cannot be empty.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName':  name,
        'bio':          bio,
        'pinnedQuote':  quote,
      });

      // Also update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      final updated = widget.user.copyWith(
        displayName: name,
        bio: bio,
        pinnedQuote: quote,
      );

      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      setState(() {
        _saving = false;
        _error  = 'Failed to save. Please try again.';
      });
    }
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
        style: TextStyle(
            color: context.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5)),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? NexColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: NexColors.indigo.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: NexColors.indigo.withValues(alpha: 0.6), size: 19)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 16 : 0, vertical: 14),
          counterStyle:
          TextStyle(color: context.textMuted, fontSize: 11),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
            top: BorderSide(color: context.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [NexColors.indigo, NexColors.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Profile',
                      style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('Update your public info',
                      style: TextStyle(
                          color: context.textMuted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: context.cardBorder, width: 1),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: context.textMuted, size: 17),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Display Name ─────────────────────────────────────────────────
          _fieldLabel('DISPLAY NAME'),
          _inputField(
            controller: _nameCtrl,
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
            maxLength: 40,
          ),

          const SizedBox(height: 16),

          // ── Bio ──────────────────────────────────────────────────────────
          _fieldLabel('BIO'),
          _inputField(
            controller: _bioCtrl,
            hint: 'Tell people a little about yourself...',
            icon: Icons.info_outline_rounded,
            maxLines: 3,
            maxLength: 150,
          ),

          const SizedBox(height: 16),

          // ── Pinned Quote ─────────────────────────────────────────────────
          _fieldLabel('PINNED QUOTE'),
          _inputField(
            controller: _quoteCtrl,
            hint: 'A quote you love (leave empty to hide)...',
            icon: Icons.format_quote_rounded,
            maxLines: 2,
            maxLength: 120,
          ),

          // ── Error ────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 15),
                const SizedBox(width: 6),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Save Button ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [NexColors.indigo, NexColors.violet],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: NexColors.violet.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                ],
              ),
              alignment: Alignment.center,
              child: _saving
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}