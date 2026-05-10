import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../services/voice_message_service.dart';
import '../models/message_model.dart';
import '../providers/chat_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../presence/presence_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final bool isGroup;
  final String? groupName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.isGroup = false,
    this.groupName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isSendingImage = false;
  Timer? _recordingTimer;
  late AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, String>> _senderCache = {};
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  int _recordingSeconds = 0;

  // Reply state
  MessageModel? _replyingTo;
  String? _replyingToSenderName;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;
  String get _displayName => widget.isGroup
      ? (widget.groupName ?? widget.otherUserName)
      : widget.otherUserName;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markAsReadProvider(widget.chatId));
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _waveController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _setReply(MessageModel msg, String senderName) {
    setState(() {
      _replyingTo = msg;
      _replyingToSenderName = senderName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToSenderName = null;
    });
  }

  // ── Image sending ─────────────────────────────────────────────────────────

  Future<void> _sendImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;

    setState(() => _isSendingImage = true);
    try {
      await ref.read(chatServiceProvider).sendImageMessage(
        chatId: widget.chatId,
        imageFile: File(picked.path),
        replyToId: _replyingTo?.id,
        replyToContent: _replyingTo?.type == MessageType.voice
            ? '🎤 Voice message'
            : _replyingTo?.content,
        replyToSenderName: _replyingToSenderName,
        replyToType: _replyingTo?.type.name,
      );
      _cancelReply();
    } catch (e, stackTrace) {
      debugPrint('IMAGE UPLOAD ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  // ── Voice recording ───────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final micGranted = await Permission.microphone.request();
    if (!micGranted.isGranted) return;

    final dir = await getTemporaryDirectory();
    _recordingPath =
    '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingSeconds = 0;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _recordingPath!,
    );

    setState(() => _isRecording = true);

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRecording) return;
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path == null || _recordingSeconds < 1) return;

    final file = File(path);
    if (!await file.exists()) return;

    setState(() => _isUploading = true);

    try {
      await VoiceMessageService.sendVoiceMessage(
        chatId: widget.chatId,
        audioFile: file,
        durationSeconds: _recordingSeconds,
        replyToId: _replyingTo?.id,
        replyToContent: _replyingTo?.type == MessageType.voice
            ? '🎤 Voice message'
            : _replyingTo?.content,
        replyToSenderName: _replyingToSenderName,
        replyToType: _replyingTo?.type.name,
      );
      _cancelReply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send voice message')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
      await file.delete();
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    if (_recordingPath != null) {
      final f = File(_recordingPath!);
      if (await f.exists()) await f.delete();
    }
    setState(() => _isRecording = false);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    await ref.read(sendMessageProvider.notifier).send(
      chatId: widget.chatId,
      content: text,
      replyToId: _replyingTo?.id,
      replyToContent: _replyingTo?.type == MessageType.voice
          ? '🎤 Voice message'
          : _replyingTo?.content,
      replyToSenderName: _replyingToSenderName,
      replyToType: _replyingTo?.type.name,
    );

    _cancelReply();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<Map<String, String>> _fetchSenderInfo(String uid) async {
    if (_senderCache.containsKey(uid)) return _senderCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      final info = {
        'name': data?['displayName'] as String? ?? 'Unknown',
        'photo': data?['photoURL'] as String? ?? '',
      };
      _senderCache[uid] = info;
      return info;
    } catch (_) {
      return {'name': 'Unknown', 'photo': ''};
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildReadReceipt(MessageModel msg) {
    final isRead = msg.readBy.length > 1;
    return Icon(
      Icons.done_all,
      size: 13,
      color: isRead ? NexColors.indigo : context.textMuted,
    );
  }

  Widget _buildWaveform({bool isActive = false}) {
    final barHeights = [10.0, 18.0, 12.0, 22.0, 14.0, 20.0, 10.0, 16.0, 8.0];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barHeights.length, (i) {
            final phase =
            ((_waveController.value + i / barHeights.length) % 1.0);
            final scale =
            isActive ? 0.4 + 0.6 * math.sin(phase * math.pi) : 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: barHeights[i] * scale,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.85)
                    : context.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRecordingBar() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [NexColors.indigo, NexColors.violet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final pulse = 0.6 +
                      0.4 * math.sin(_waveController.value * 2 * math.pi);
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: pulse),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                'Recording... ${_fmt(_recordingSeconds)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RepaintBoundary(child: _buildWaveform(isActive: true)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _stopAndSendRecording,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: NexColors.indigo, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: NexColors.indigo),
          ),
          const SizedBox(width: 10),
          Text('Sending voice message...',
              style: TextStyle(color: context.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReplyPreviewBar() {
    if (_replyingTo == null) return const SizedBox.shrink();
    final isVoice = _replyingTo!.type == MessageType.voice;
    final isImage = _replyingTo!.type == MessageType.image;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: context.cardSurface,
        border: Border(
          top: BorderSide(color: context.cardBorder, width: 1),
          left: const BorderSide(color: NexColors.indigo, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingToSenderName ?? 'Unknown',
                  style: const TextStyle(
                    color: NexColors.indigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isVoice) ...[
                      Icon(Icons.mic_rounded,
                          size: 13, color: context.textMuted),
                      const SizedBox(width: 4),
                    ] else if (isImage) ...[
                      Icon(Icons.image_outlined,
                          size: 13, color: context.textMuted),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        isVoice
                            ? 'Voice message'
                            : isImage
                            ? 'Photo'
                            : (_replyingTo!.content.length > 60
                            ? '${_replyingTo!.content.substring(0, 60)}...'
                            : _replyingTo!.content),
                        style:
                        TextStyle(color: context.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              child:
              Icon(Icons.close_rounded, size: 18, color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyQuote(MessageModel msg, bool isMe) {
    if (msg.replyToId == null) return const SizedBox.shrink();
    final isVoice = msg.replyToType == MessageType.voice;
    final isImage = msg.replyToType == MessageType.image;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : context.cardSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white60 : NexColors.indigo,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.replyToSenderName ?? 'Unknown',
            style: TextStyle(
              color: isMe ? Colors.white70 : NexColors.indigo,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (isVoice) ...[
                Icon(Icons.mic_rounded,
                    size: 11,
                    color: isMe ? Colors.white60 : context.textMuted),
                const SizedBox(width: 3),
              ] else if (isImage) ...[
                Icon(Icons.image_outlined,
                    size: 11,
                    color: isMe ? Colors.white60 : context.textMuted),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  isVoice
                      ? 'Voice message'
                      : isImage
                      ? 'Photo'
                      : (msg.replyToContent ?? ''),
                  style: TextStyle(
                    color: isMe ? Colors.white60 : context.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAvatar() {
    if (widget.isGroup) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [NexColors.indigo, NexColors.violet],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: context.cardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: NexColors.indigo.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: NexColors.indigo.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 19,
        backgroundImage: widget.otherUserAvatar.isNotEmpty
            ? NetworkImage(widget.otherUserAvatar)
            : null,
        backgroundColor: context.receivedBubbleBg,
        child: widget.otherUserAvatar.isEmpty
            ? Text(
          widget.otherUserName.isNotEmpty
              ? widget.otherUserName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: NexColors.indigo,
            fontWeight: FontWeight.w700,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildVoiceBubbleLayout({
    required MessageModel msg,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (msg.replyToId != null) _buildReplyQuote(msg, isMe),
              _VoiceBubble(
                audioUrl: msg.mediaUrl ?? '',
                duration: msg.duration ?? 0,
                isMe: isMe,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubbleLayout({
    required MessageModel msg,
    required bool isMe,
    required String senderName,
  }) {
    final timeStr = DateFormat('h:mm a').format(msg.sentAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isMe ? NexColors.indigo : context.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              if (msg.replyToId != null) _buildReplyQuote(msg, isMe),
              _ImageBubble(url: msg.mediaUrl ?? '', isMe: isMe),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr,
                      style: TextStyle(
                          fontSize: 11, color: context.textMuted)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildReadReceipt(msg),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wrapWithSwipe({
    required Widget child,
    required MessageModel msg,
    required String senderName,
  }) {
    return Dismissible(
      key: ValueKey('swipe_${msg.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _showDeleteDialog(msg);
        } else if (direction == DismissDirection.startToEnd) {
          _setReply(msg, senderName);
        }
        return false;
      },
      background: _buildReplyBackground(),
      secondaryBackground: _buildDeleteBackground(),
      child: child,
    );
  }

  Widget _buildReplyBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: NexColors.indigo.withValues(alpha: 0.1),
      child:
      const Icon(Icons.reply_rounded, color: NexColors.indigo, size: 26),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent.withValues(alpha: 0.1),
      child:
      const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 26),
    );
  }

  void _showDeleteDialog(MessageModel msg) {
    final isMe = msg.senderId == _myUid;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: context.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(deleteMessageProvider).deleteForEveryone(
                    chatId: widget.chatId,
                    messageId: msg.id,
                    mediaUrl: msg.mediaUrl,
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: context.textMuted),
              title: Text('Delete for me',
                  style: TextStyle(color: context.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(deleteMessageProvider).deleteForMe(
                  chatId: widget.chatId,
                  messageId: msg.id,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.close_rounded, color: context.textMuted),
              title:
              Text('Cancel', style: TextStyle(color: context.textMuted)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = 'Today';
    } else if (msgDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: NexColors.indigo.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(MessageModel msg) {
    final isMe = msg.senderId == _myUid;

    if (msg.deletedForEveryone) return _buildDeletedBubble(isMe);
    if (msg.deletedFor.contains(_myUid)) return const SizedBox.shrink();

    final timeStr = DateFormat('h:mm a').format(msg.sentAt);

    if (widget.isGroup && !isMe) {
      return FutureBuilder<Map<String, String>>(
        future: _fetchSenderInfo(msg.senderId),
        builder: (context, snapshot) {
          final name = snapshot.data?['name'] ?? '...';
          final photo = snapshot.data?['photo'] ?? '';
          final bubble = msg.type == MessageType.voice
              ? _buildVoiceBubbleLayout(msg: msg, isMe: isMe)
              : msg.type == MessageType.image
              ? _buildImageBubbleLayout(
              msg: msg, isMe: isMe, senderName: name)
              : _buildBubbleLayout(
            msg: msg,
            isMe: isMe,
            timeStr: timeStr,
            senderName: name,
            senderPhoto: photo,
          );
          return _wrapWithSwipe(child: bubble, msg: msg, senderName: name);
        },
      );
    }

    final senderName = isMe ? 'Me' : widget.otherUserName;
    final bubble = msg.type == MessageType.voice
        ? _buildVoiceBubbleLayout(msg: msg, isMe: isMe)
        : msg.type == MessageType.image
        ? _buildImageBubbleLayout(
        msg: msg, isMe: isMe, senderName: senderName)
        : _buildBubbleLayout(
      msg: msg,
      isMe: isMe,
      timeStr: timeStr,
      senderName: senderName,
      senderPhoto: isMe ? '' : widget.otherUserAvatar,
    );

    return _wrapWithSwipe(child: bubble, msg: msg, senderName: senderName);
  }

  Widget _buildDeletedBubble(bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 14, color: context.textMuted),
                const SizedBox(width: 6),
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleLayout({
    required MessageModel msg,
    required bool isMe,
    required String timeStr,
    required String senderName,
    required String senderPhoto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: isMe
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr,
                          style: TextStyle(
                              fontSize: 11, color: context.textMuted)),
                      const SizedBox(width: 4),
                      _buildReadReceipt(msg),
                    ],
                  ),
                ),
              ],
            )
                : _MessageCard(
              text: msg.content,
              senderName: senderName,
              avatarUrl: senderPhoto,
              alignRight: false,
              replyQuote: msg.replyToId != null
                  ? _buildReplyQuote(msg, false)
                  : null,
            ),
          ),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 1.5,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.cardBorder.withValues(alpha: 0.2),
                        context.cardBorder,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [NexColors.indigo, NexColors.violet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isMe
                ? _MessageCard(
              text: msg.content,
              senderName: 'Me',
              avatarUrl: '',
              alignRight: true,
              replyQuote: msg.replyToId != null
                  ? _buildReplyQuote(msg, true)
                  : null,
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(timeStr,
                      style: TextStyle(
                          fontSize: 11, color: context.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? NexColors.darkCard
                : NexColors.lightPageLight,
            border: Border(
                bottom: BorderSide(color: context.cardBorder, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  _buildAppBarAvatar(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_displayName,
                            style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        if (!widget.isGroup)
                          _PresenceDot(uid: widget.otherUserId),
                        if (widget.isGroup)
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.groupInfo,
                              arguments: {'chatId': widget.chatId},
                            ),
                            child: Text('View group info',
                                style: TextStyle(
                                    color: context.textMuted, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  if (!widget.isGroup) ...[
                    IconButton(
                        icon: Icon(Icons.videocam_outlined,
                            color: context.textPrimary),
                        onPressed: () {}),
                    IconButton(
                        icon: Icon(Icons.phone_outlined,
                            color: context.textPrimary),
                        onPressed: () {}),
                  ],
                  IconButton(
                      icon:
                      Icon(Icons.more_vert, color: context.textPrimary),
                      onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.pageGradient),
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: NexColors.indigo)),
                error: (e, st) => Center(
                    child: Text('Something went wrong',
                        style: TextStyle(color: context.textMuted))),
                data: (messages) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(markAsReadProvider(widget.chatId));
                    _scrollToBottom(animate: false);
                  });

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        widget.isGroup
                            ? 'Group created!\nSay hello to everyone 👋'
                            : 'No messages yet\nSay hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.textMuted,
                            fontSize: 14,
                            height: 1.6),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final msgDay = DateTime(
                          msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);

                      bool showSeparator = false;
                      if (index == 0) {
                        showSeparator = true;
                      } else {
                        final prevMsg = messages[index - 1];
                        final prevDay = DateTime(prevMsg.sentAt.year,
                            prevMsg.sentAt.month, prevMsg.sentAt.day);
                        showSeparator = msgDay != prevDay;
                      }

                      return Column(
                        children: [
                          if (showSeparator)
                            _buildDateSeparator(msg.sentAt),
                          _buildBubble(msg),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildReplyPreviewBar(),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: context.isDark
                    ? NexColors.darkCard
                    : NexColors.lightPageLight,
                border: Border(
                    top: BorderSide(color: context.cardBorder, width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: NexColors.indigo.withValues(alpha: 0.06),
                      offset: const Offset(0, -2),
                      blurRadius: 10),
                ],
              ),
              child: SafeArea(
                child: _isUploading
                    ? _buildUploadingBar()
                    : _isRecording
                    ? _buildRecordingBar()
                    : Row(
                  children: [
                    GestureDetector(
                      onTap: _isSendingImage ? null : _sendImage,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: context.receivedBubbleBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: context.cardBorder, width: 1),
                        ),
                        child: _isSendingImage
                            ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NexColors.indigo),
                        )
                            : const Icon(Icons.add_rounded,
                            color: NexColors.indigo, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        cursorColor: NexColors.indigo,
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14),
                        onChanged: (val) {
                          ref
                              .read(typingNotifierProvider.notifier)
                              .setTyping(widget.chatId,
                              isTyping: val.isNotEmpty);
                        },
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: context.textMuted,
                              fontSize: 14),
                          filled: true,
                          fillColor: context.cardSurface,
                          contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  color: context.cardBorder,
                                  width: 1)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(24),
                              borderSide: BorderSide(
                                  color: context.cardBorder,
                                  width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                  color: NexColors.indigo,
                                  width: 1.5)),
                          suffixIcon: Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              color: context.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, child) {
                        final hasText =
                            value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: hasText
                              ? _sendMessage
                              : _startRecording,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  NexColors.indigo,
                                  NexColors.violet
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: NexColors.violet
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Icon(
                              hasText
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message card ──────────────────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final String text;
  final String senderName;
  final String avatarUrl;
  final bool alignRight;
  final Widget? replyQuote;

  const _MessageCard({
    required this.text,
    required this.senderName,
    required this.avatarUrl,
    required this.alignRight,
    this.replyQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight && avatarUrl.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: context.cardBorder, width: 1.5)),
                child: CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(avatarUrl)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              senderName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color:
                alignRight ? NexColors.indigo : context.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: alignRight
                ? const LinearGradient(
                colors: [NexColors.indigo, NexColors.violet],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight)
                : null,
            color: alignRight ? null : context.receivedBubbleBg,
            border: alignRight
                ? null
                : Border.all(
                color: context.receivedBubbleBorder, width: 0.8),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(alignRight ? 16 : 4),
              bottomRight: Radius.circular(alignRight ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: alignRight
                    ? NexColors.indigo.withValues(alpha: 0.2)
                    : context.cardBorder.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyQuote != null) replyQuote!,
              Text(
                text,
                style: TextStyle(
                  color: alignRight ? Colors.white : context.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Presence dot ──────────────────────────────────────────────────────────────

class _PresenceDot extends ConsumerWidget {
  final String uid;
  const _PresenceDot({required this.uid});
  static const _green = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(presenceProvider(uid));
    return presenceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (presence) {
        final isOnline = presence.isOnline;
        return Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isOnline ? _green : context.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              presence.lastSeenLabel,
              style: TextStyle(
                color: isOnline ? _green : context.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Voice bubble ──────────────────────────────────────────────────────────────

class _VoiceBubble extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final bool isMe;
  const _VoiceBubble({
    required this.audioUrl,
    required this.duration,
    required this.isMe,
  });

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.setUrl(widget.audioUrl);
      _player.play();
      setState(() => _isPlaying = true);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: widget.isMe
            ? const LinearGradient(
            colors: [NexColors.indigo, NexColors.violet])
            : null,
        color: widget.isMe ? null : context.receivedBubbleBg,
        border: widget.isMe
            ? null
            : Border.all(color: context.receivedBubbleBorder, width: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: NexColors.indigo.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: widget.isMe ? Colors.white : NexColors.indigo,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.mic_rounded,
              size: 14,
              color: widget.isMe ? Colors.white70 : context.textMuted),
          const SizedBox(width: 4),
          Text(
            _fmt(widget.duration),
            style: TextStyle(
              color: widget.isMe ? Colors.white : context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image bubble ──────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  const _ImageBubble({required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Hero(
        tag: url,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          child: Image.network(
            url,
            width: 220,
            height: 260,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 220,
                height: 260,
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                    color: NexColors.indigo,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 220,
              height: 100,
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Icon(Icons.broken_image_outlined,
                  color: context.textMuted, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenImage(url: url),
    ));
  }
}

// ── Full screen image viewer ──────────────────────────────────────────────────

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}