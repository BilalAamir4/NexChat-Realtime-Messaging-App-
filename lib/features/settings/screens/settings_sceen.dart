import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

// ─── Data models ────────────────────────────────────────────────────────────

enum SettingsSectionId {
  appearance,
  notifications,
  privacySecurity,
  chatMedia,
  account,
  storageData,
  about,
}

class SettingsItem {
  final String label;
  final String? subtitle;
  final IconData icon;
  final SettingsItemType type;
  final String? value;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.label,
    this.subtitle,
    required this.icon,
    this.type = SettingsItemType.arrow,
    this.value,
    this.onTap,
  });
}

enum SettingsItemType { arrow, toggle, value, destructive }

// ─── Main Screen ─────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _headerCollapsed = false;

  // Preview state — mirrors live settings changes
  bool _previewDark = false;
  bool _notificationsOn = true;
  bool _readReceiptsOn = true;
  bool _typingIndicatorOn = true;
  bool _mediaAutoDownload = false;
  String _fontSize = 'Medium';

  // Which section cards are expanded
  final Set<SettingsSectionId> _expanded = {SettingsSectionId.appearance};

  // Animation controllers for section expansion
  final Map<SettingsSectionId, AnimationController> _sectionControllers = {};

  static const double _kHeaderMax = 260.0;
  static const double _kHeaderMin = 56.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    for (final id in SettingsSectionId.values) {
      _sectionControllers[id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: id == SettingsSectionId.appearance ? 1.0 : 0.0,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDark = ref.read(isDarkProvider);
      setState(() => _previewDark = isDark);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _sectionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > (_kHeaderMax - _kHeaderMin - 20);
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
  }

  void _toggleSection(SettingsSectionId id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
        _sectionControllers[id]!.reverse();
      } else {
        _expanded.add(id);
        _sectionControllers[id]!.forward();
      }
    });
  }

  void _toggleTheme() {
    final notifier = ref.read(themeModeProvider.notifier);
    notifier.toggle();
    setState(() => _previewDark = !_previewDark);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor:
      isDark ? NexColors.darkPage : NexColors.lightPageLight,
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [NexColors.darkPage, const Color(0xFF0D0D1A)]
                      : [NexColors.lightPageDark, NexColors.lightPageLight],
                ),
              ),
            ),
          ),

          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Collapsing header ──────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _SettingsHeaderDelegate(
                  maxHeight: _kHeaderMax,
                  minHeight: _kHeaderMin,
                  isDark: isDark,
                  collapsed: _headerCollapsed,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),

              // ── Live preview card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: _LivePreviewCard(
                    isDark: _previewDark,
                    fontSize: _fontSize,
                  ),
                ),
              ),

              // ── Section cards ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.appearance,
                      icon: Icons.palette_outlined,
                      label: 'Appearance',
                      accentColor: NexColors.indigo,
                      isDark: isDark,
                      children: [
                        _ThemeToggleRow(
                          isDark: _previewDark,
                          onToggle: _toggleTheme,
                          contextIsDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _FontSizeRow(
                          value: _fontSize,
                          isDark: isDark,
                          onChange: (v) => setState(() => _fontSize = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.notifications,
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      accentColor: const Color(0xFF7C3AED),
                      isDark: isDark,
                      children: [
                        _ToggleRow(
                          icon: Icons.notifications_active_outlined,
                          label: 'Push notifications',
                          subtitle: 'Messages, calls & mentions',
                          value: _notificationsOn,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _notificationsOn = v),
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.volume_up_outlined,
                          label: 'Notification sound',
                          value: 'Default',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.do_not_disturb_outlined,
                          label: 'Do not disturb',
                          value: 'Off',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.privacySecurity,
                      icon: Icons.lock_outline,
                      label: 'Privacy & security',
                      accentColor: const Color(0xFF059669),
                      isDark: isDark,
                      children: [
                        _ToggleRow(
                          icon: Icons.done_all_rounded,
                          label: 'Read receipts',
                          subtitle: 'Show when you\'ve read messages',
                          value: _readReceiptsOn,
                          isDark: isDark,
                          onChanged: (v) {
                            setState(() {
                              _readReceiptsOn = v;
                            });
                          },
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ToggleRow(
                          icon: Icons.keyboard_outlined,
                          label: 'Typing indicator',
                          subtitle: 'Show when you\'re typing',
                          value: _typingIndicatorOn,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _typingIndicatorOn = v),
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.block_outlined,
                          label: 'Blocked contacts',
                          value: '0',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.fingerprint,
                          label: 'App lock',
                          value: 'Off',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.chatMedia,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat & media',
                      accentColor: const Color(0xFF0EA5E9),
                      isDark: isDark,
                      children: [
                        _ToggleRow(
                          icon: Icons.download_outlined,
                          label: 'Auto-download media',
                          subtitle: 'On Wi-Fi and mobile data',
                          value: _mediaAutoDownload,
                          isDark: isDark,
                          onChanged: (v) =>
                              setState(() => _mediaAutoDownload = v),
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.wallpaper_outlined,
                          label: 'Chat wallpaper',
                          value: 'None',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.translate_outlined,
                          label: 'Message translation',
                          value: 'Off',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.account,
                      icon: Icons.person_outline_rounded,
                      label: 'Account',
                      accentColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                      children: [
                        _ArrowRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone number',
                          value: '+92 ···· ···',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.email_outlined,
                          label: 'Email address',
                          value: 'Not set',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete account',
                          isDark: isDark,
                          destructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.storageData,
                      icon: Icons.storage_outlined,
                      label: 'Storage & data',
                      accentColor: const Color(0xFFEC4899),
                      isDark: isDark,
                      children: [
                        _ArrowRow(
                          icon: Icons.pie_chart_outline,
                          label: 'Storage usage',
                          value: '142 MB',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.cleaning_services_outlined,
                          label: 'Clear cache',
                          value: '12 MB',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.cloud_upload_outlined,
                          label: 'Backup & restore',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildSectionCard(
                      context: context,
                      id: SettingsSectionId.about,
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      accentColor: NexColors.lightSlateMid,
                      isDark: isDark,
                      children: [
                        _ArrowRow(
                          icon: Icons.star_outline_rounded,
                          label: 'Rate NexChat',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.description_outlined,
                          label: 'Terms of service',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        _ArrowRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy policy',
                          isDark: isDark,
                        ),
                        _SettingsDivider(isDark: isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.tag_rounded,
                                  size: 18,
                                  color: isDark
                                      ? NexColors.darkTextPrimary
                                      .withValues(alpha: 0.4)
                                      : NexColors.lightSlateMuted),
                              const SizedBox(width: 12),
                              Text(
                                'Version 1.0.0 (build 42)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? NexColors.darkTextPrimary
                                      .withValues(alpha: 0.4)
                                      : NexColors.lightSlateMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required SettingsSectionId id,
    required IconData icon,
    required String label,
    required Color accentColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    final isExpanded = _expanded.contains(id);
    final controller = _sectionControllers[id]!;
    final cardBg = isDark ? NexColors.darkCard : NexColors.lightCardSurface;
    final border = isDark ? NexColors.darkBorder : NexColors.indigo200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NexColors.indigo.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Section header tap target
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _toggleSection(id),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? NexColors.darkTextPrimary
                              : NexColors.lightSlateDark,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark
                              ? NexColors.darkTextPrimary.withValues(alpha: 0.4)
                              : NexColors.lightSlateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expandable content
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: controller,
                curve: Curves.easeInOut,
              ),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: border,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Collapsing header delegate ───────────────────────────────────────────────

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final bool isDark;
  final bool collapsed;
  final VoidCallback onBack;

  const _SettingsHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.isDark,
    required this.collapsed,
    required this.onBack,
  });

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_SettingsHeaderDelegate old) =>
      old.isDark != isDark || old.collapsed != collapsed;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
    final bgColor = isDark ? NexColors.darkCard : NexColors.lightCardSurface;
    final borderColor = isDark ? NexColors.darkBorder : NexColors.indigo200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: t > 0.5
            ? bgColor.withValues(alpha: t)
            : Colors.transparent,
        border: t > 0.5
            ? Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: t),
            width: 1,
          ),
        )
            : null,
      ),
      child: Stack(
        children: [
          // Expanded: large hero area
          if (t < 0.8)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: (1 - t * 1.5).clamp(0.0, 1.0),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    // Large settings glyph
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [NexColors.indigo, NexColors.violet],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: NexColors.indigo.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? NexColors.darkTextPrimary
                            : NexColors.lightSlateDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customise your NexChat experience',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? NexColors.darkTextPrimary.withValues(alpha: 0.45)
                            : NexColors.lightSlateMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Back button — always visible
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: isDark
                    ? NexColors.darkTextPrimary
                    : NexColors.lightSlateDark,
              ),
              onPressed: onBack,
            ),
          ),

          // Collapsed title
          if (t > 0.7)
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: ((t - 0.7) * 3.33).clamp(0.0, 1.0),
                child: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? NexColors.darkTextPrimary
                          : NexColors.lightSlateDark,
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

// ─── Live preview card ────────────────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  final bool isDark;
  final String fontSize;

  const _LivePreviewCard({required this.isDark, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? NexColors.darkCard : NexColors.lightCardSurface;
    final border = isDark ? NexColors.darkBorder : NexColors.indigo200;

    final baseFontSize = fontSize == 'Small'
        ? 11.0
        : fontSize == 'Large'
        ? 15.0
        : 13.0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NexColors.indigo.withValues(alpha: isDark ? 0.1 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? NexColors.indigo.withValues(alpha: 0.6)
                        : NexColors.indigo,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? NexColors.darkTextPrimary.withValues(alpha: 0.5)
                        : NexColors.lightSlateMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? NexColors.darkSurface
                        : NexColors.indigo100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDark ? '🌙 Dark' : '☀️ Light',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? NexColors.indigo200 : NexColors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini chat preview
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? NexColors.darkPage
                  : NexColors.lightPageDark.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? NexColors.darkBorder
                    : NexColors.indigo200.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                // Received bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? NexColors.darkReceivedBg
                          : NexColors.indigo100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(
                        color: isDark
                            ? NexColors.darkBorder
                            : NexColors.indigo200,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Hey! How\'s it going? 👋',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        color: isDark
                            ? NexColors.darkTextPrimary
                            : NexColors.lightSlateDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Sent bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NexColors.indigo, NexColors.violet],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      'All good, loving NexChat! ✨',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Read receipt row
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: isDark
                            ? NexColors.indigo200
                            : NexColors.indigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Seen · 2m ago',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? NexColors.darkTextPrimary.withValues(alpha: 0.35)
                              : NexColors.lightSlateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theme toggle row ─────────────────────────────────────────────────────────

class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final bool contextIsDark;

  const _ThemeToggleRow({
    required this.isDark,
    required this.onToggle,
    required this.contextIsDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              size: 20,
              color: contextIsDark
                  ? NexColors.darkTextPrimary
                  : NexColors.lightSlateDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: contextIsDark
                        ? NexColors.darkTextPrimary
                        : NexColors.lightSlateDark,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isDark ? 'Dark mode' : 'Light mode',
                    key: ValueKey(isDark),
                    style: TextStyle(
                      fontSize: 12,
                      color: contextIsDark
                          ? NexColors.darkTextPrimary.withValues(alpha: 0.45)
                          : NexColors.lightSlateMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _NexSwitch(value: isDark, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }
}

// ─── Font size row ────────────────────────────────────────────────────────────

class _FontSizeRow extends StatelessWidget {
  final String value;
  final bool isDark;
  final ValueChanged<String> onChange;

  const _FontSizeRow({
    required this.value,
    required this.isDark,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final sizes = ['Small', 'Medium', 'Large'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 20,
                color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
              ),
              const SizedBox(width: 12),
              Text(
                'Font size',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: sizes.map((s) {
              final selected = s == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChange(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: s != sizes.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                        colors: [NexColors.indigo, NexColors.violet],
                      )
                          : null,
                      color: selected
                          ? null
                          : isDark
                          ? NexColors.darkSurface
                          : NexColors.indigo100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : isDark
                            ? NexColors.darkBorder
                            : NexColors.indigo200,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : isDark
                              ? NexColors.darkTextPrimary.withValues(alpha: 0.6)
                              : NexColors.lightSlateMid,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Shared row widgets ───────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: isDark ? NexColors.darkTextPrimary : NexColors.lightSlateDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? NexColors.darkTextPrimary
                        : NexColors.lightSlateDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? NexColors.darkTextPrimary.withValues(alpha: 0.45)
                          : NexColors.lightSlateMuted,
                    ),
                  ),
              ],
            ),
          ),
          _NexSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ArrowRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;
  final bool destructive;

  const _ArrowRow({
    required this.icon,
    required this.label,
    this.value,
    required this.isDark,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFEF4444)
        : isDark
        ? NexColors.darkTextPrimary
        : NexColors.lightSlateDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? NexColors.darkTextPrimary.withValues(alpha: 0.4)
                        : NexColors.lightSlateMuted,
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? NexColors.darkTextPrimary.withValues(alpha: 0.3)
                    : NexColors.lightSlateMuted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final bool isDark;
  const _SettingsDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 48,
      endIndent: 0,
      color: isDark
          ? NexColors.darkBorder.withValues(alpha: 0.6)
          : NexColors.indigo200.withValues(alpha: 0.5),
    );
  }
}

// ─── Custom NexSwitch ─────────────────────────────────────────────────────────

class _NexSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NexSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
            colors: [NexColors.indigo, NexColors.violet],
          )
              : null,
          color: value ? null : NexColors.lightSlateMuted.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}