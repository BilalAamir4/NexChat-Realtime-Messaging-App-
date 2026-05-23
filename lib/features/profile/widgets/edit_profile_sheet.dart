import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // ← ADDED
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Photo state — changed from File? to XFile? to support web
  XFile? _pickedImage; // ← CHANGED
  bool _uploadingPhoto = false;

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

  // ─── Photo Picker ─────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.pop(context); // close the source picker bottom sheet
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = picked); // ← CHANGED: assign XFile directly
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not access camera or gallery.');
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        decoration: BoxDecoration(
          color: context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: context.cardBorder, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choose photo',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (widget.user.photoUrl.isNotEmpty || _pickedImage != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pickedImage = null);
                  // Mark photo for removal on save
                  _removePhoto = true;
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF2A1515)
                        : context.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                        width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Remove photo',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _removePhoto = false;

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NexColors.indigo, NexColors.violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─── Upload photo to Firebase Storage ────────────────────────────────────

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return null;
    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');

      // ← CHANGED: use putData on web, putFile on mobile
      if (kIsWeb) {
        final bytes = await _pickedImage!.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(
          File(_pickedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

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
      String? newPhotoUrl;

      if (_pickedImage != null) {
        newPhotoUrl = await _uploadPhoto(uid);
        if (newPhotoUrl == null) {
          setState(() {
            _saving = false;
            _error = 'Photo upload failed. Please try again.';
          });
          return;
        }
      }

      final updates = <String, dynamic>{
        'displayName': name,
        'bio': bio,
        'pinnedQuote': quote,
      };

      if (newPhotoUrl != null) {
        updates['photoUrl'] = newPhotoUrl;
      } else if (_removePhoto) {
        updates['photoUrl'] = '';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updates);

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
      if (newPhotoUrl != null) {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(newPhotoUrl);
      }

      final updated = widget.user.copyWith(
        displayName: name,
        bio: bio,
        pinnedQuote: quote,
        photoUrl: newPhotoUrl ??
            (_removePhoto ? '' : widget.user.photoUrl),
      );

      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Failed to save. Please try again.';
      });
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
              ? Icon(icon,
              color: NexColors.indigo.withValues(alpha: 0.6), size: 19)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 16 : 0, vertical: 14),
          counterStyle: TextStyle(color: context.textMuted, fontSize: 11),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Determine what to show in the avatar preview
    final currentPhotoUrl =
    _removePhoto ? '' : widget.user.photoUrl;
    final hasExistingPhoto =
        currentPhotoUrl.isNotEmpty && _pickedImage == null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color:
        context.isDark ? NexColors.darkCard : NexColors.lightPageLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
            top: BorderSide(color: context.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ────────────────────────────────────────────────────
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

          // ── Header ────────────────────────────────────────────────────
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
                      style:
                      TextStyle(color: context.textMuted, fontSize: 12)),
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
                    border: Border.all(
                        color: context.cardBorder, width: 1),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: context.textMuted, size: 17),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Photo Picker ──────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _showPhotoSourceSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (_pickedImage == null && !hasExistingPhoto)
                          ? const LinearGradient(
                          colors: [NexColors.indigo, NexColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)
                          : null,
                      border: Border.all(
                          color: NexColors.indigo.withValues(alpha: 0.4),
                          width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: NexColors.indigo.withValues(alpha: 0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ClipOval(
                      // ← CHANGED: web uses Image.network with blob URL,
                      //   mobile uses Image.file
                      child: _pickedImage != null
                          ? kIsWeb
                          ? Image.network(
                        _pickedImage!.path,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      )
                          : Image.file(
                        File(_pickedImage!.path),
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      )
                          : hasExistingPhoto
                          ? Image.network(currentPhotoUrl,
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40))
                          : const Icon(Icons.person,
                          color: Colors.white, size: 40),
                    ),
                  ),

                  // Camera badge
                  Positioned(
                    bottom: 0,
                    right: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [NexColors.indigo, NexColors.violet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.isDark
                                ? NexColors.darkCard
                                : NexColors.lightPageLight,
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: NexColors.indigo.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: _uploadingPhoto
                          ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Tap to change photo',
              style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 20),

          // ── Display Name ──────────────────────────────────────────────
          _fieldLabel('DISPLAY NAME'),
          _inputField(
            controller: _nameCtrl,
            hint: 'Your full name',
            icon: Icons.person_outline_rounded,
            maxLength: 40,
          ),

          const SizedBox(height: 16),

          // ── Bio ───────────────────────────────────────────────────────
          _fieldLabel('BIO'),
          _inputField(
            controller: _bioCtrl,
            hint: 'Tell people a little about yourself...',
            icon: Icons.info_outline_rounded,
            maxLines: 3,
            maxLength: 150,
          ),

          const SizedBox(height: 16),

          // ── Pinned Quote ──────────────────────────────────────────────
          _fieldLabel('PINNED QUOTE'),
          _inputField(
            controller: _quoteCtrl,
            hint: 'A quote you love (leave empty to hide)...',
            icon: Icons.format_quote_rounded,
            maxLines: 2,
            maxLength: 120,
          ),

          // ── Error ─────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Save Button ───────────────────────────────────────────────
          GestureDetector(
            onTap: (_saving || _uploadingPhoto) ? null : _save,
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
              child: (_saving || _uploadingPhoto)
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(
                    _uploadingPhoto
                        ? 'Uploading photo...'
                        : 'Saving...',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              )
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