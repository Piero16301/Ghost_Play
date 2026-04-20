import 'package:flutter/material.dart';

class AppFilledButton extends StatelessWidget {
  const AppFilledButton({
    this.onPressed,
    this.icon,
    this.label,
    this.innerPadding,
    this.color,
    this.isOnlyIcon = false,
    super.key,
  });

  final void Function()? onPressed;
  final Widget? icon;
  final String? label;
  final EdgeInsetsGeometry? innerPadding;
  final Color? color;
  final bool isOnlyIcon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding:
            innerPadding ??
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: icon != null && !isOnlyIcon ? icon : null,
      label: label != null
          ? Text(
              label ?? '',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                fontWeight: FontWeight.w600,
              ),
            )
          : icon!,
    );
  }
}
