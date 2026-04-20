import 'package:flutter/material.dart';
import 'package:shoqlist/constants/app_colors.dart';

/// Dyskretny header dla ekranów poza main tab scaffoldem.
/// Zawiera optional chevron back (leading) + duży różowy tytuł + opcjonalne
/// akcje trailing (np. share, search). Bez pełnego AppBara — zachowuje
/// minimalistyczny look apki z dużym tytułem w stylu iOS Large Title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions = const [],
    this.titleColor,
  });

  final String title;
  final bool showBackButton;
  final List<Widget> actions;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        titleColor ?? Theme.of(context).primaryTextTheme.headlineMedium?.color;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 32),
              color: AppColors.brandPink,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .primaryTextTheme
                  .headlineMedium
                  ?.copyWith(color: resolvedColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
