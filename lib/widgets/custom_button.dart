import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final String? iconAsset;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? outlineColor;
  final Color? textColor;
  final Color? loadingColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.iconAsset,
    this.backgroundColor,
    this.foregroundColor,
    this.outlineColor,
    this.textColor,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedForeground = foregroundColor ?? AppColor.textOnPrimary;
    final resolvedTextColor =
        textColor ?? (isOutlined ? AppColor.textHint : resolvedForeground);
    final resolvedOutlineColor = outlineColor ?? AppColor.textHint;

    final buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: loadingColor ?? resolvedTextColor,
            ),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              if (iconAsset != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(iconAsset!, width: 20, height: 20),
                ),
              Text(
                text,
                style: TextStyle(
                  color: resolvedTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            foregroundColor: resolvedTextColor,
            side: BorderSide(color: resolvedOutlineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColor.secondary,
          disabledBackgroundColor: backgroundColor ?? AppColor.secondary,
          foregroundColor: resolvedForeground,
          disabledForegroundColor: resolvedForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: buttonChild,
      ),
    );
  }
}
