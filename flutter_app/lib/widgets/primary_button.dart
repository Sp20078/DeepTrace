import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isSmall;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isSmall ? 40 : 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppColors.primary,
          foregroundColor: isOutlined ? AppColors.primary : Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 24,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isOutlined
                ? const BorderSide(color: AppColors.primary, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 16 : 20),
              SizedBox(width: isSmall ? 6 : 8),
            ],
            Text(
              label,
              style: (isSmall ? AppTheme.labelLarge : AppTheme.subtitleMedium)
                  .copyWith(
                color: isOutlined ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
