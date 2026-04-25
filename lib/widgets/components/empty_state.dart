import 'package:flutter/material.dart';
import 'package:shoqlist/constants/app_colors.dart';

/// Centrowany empty/state placeholder — duża wyciszona ikona + krótki
/// komunikat. Używany na ekranach gdzie brak danych byłby goły:
/// search friends (no input / not found / already friend), friend requests
/// (no requests), etc.
///
/// Hierarchia: 88pt ikona + 16px gap + bodyLarge text bold w `neutralIcon`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 88, color: AppColors.neutralIcon),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).primaryTextTheme.bodyLarge?.copyWith(
                  color: AppColors.neutralIcon,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
