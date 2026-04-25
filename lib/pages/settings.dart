import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/components/native_ad_banner.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  void _signOut(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    ref.read(shoppingListsProvider).clearDisplayedData();
    firebaseAuthVM.signOut();
  }

  void _changeNickname(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    final toolsVM = ref.read(toolsProvider);
    firebaseAuthVM.changeNickname(toolsVM.newNicknameController.text);
    Navigator.of(context).pop();
  }

  void _showDialogWithChangeNickname(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).clearNewNicknameController();
    showDialog(
      context: context,
      builder: (context) => ChangeName(_changeNickname, 'Change nickname'),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => YesNoDialog(
        (ctx, r) => r.read(firebaseProvider).deleteEveryDataRelatedToCurrentUser(),
        context.l10n.deleteAccountMsg,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final user = firebaseAuthVM.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        context.l10n.settings,
                        style: Theme.of(context).primaryTextTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProfileCard(
                      nickname: user.nickname,
                      email: user.email,
                      onEdit: () =>
                          _showDialogWithChangeNickname(context, ref),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: context.l10n.settings),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.logout,
                          iconColor: AppColors.brandPink,
                          label: context.l10n.signOut,
                          onTap: () => _signOut(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(
                      label: context.l10n.deleteAccount,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      borderColor: Colors.red.shade200,
                      children: [
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          iconColor: Colors.red.shade400,
                          label: context.l10n.deleteAccount,
                          labelColor: Colors.red.shade400,
                          onTap: () => _confirmDeleteAccount(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const NativeAdBanner(),
          ],
        ),
      ),
    );
  }
}

/// Hero card z avatarem (inicjały), nick, email, edit pen po prawej.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.email,
    required this.onEdit,
  });

  final String nickname;
  final String email;
  final VoidCallback onEdit;

  String get _initials {
    final source = nickname.isNotEmpty ? nickname : email;
    if (source.isEmpty) return '?';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrayWarm,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.brandPink,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Epilogue',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nickname.isNotEmpty ? nickname : '—',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Epilogue',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Epilogue',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: context.l10n.changeNicknameTitle,
            icon: const Icon(Icons.edit_outlined, color: AppColors.brandPink),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color ?? Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, this.borderColor});

  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
          indent: 56,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceGrayWarm,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: rows),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.brandPink, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Epilogue',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
