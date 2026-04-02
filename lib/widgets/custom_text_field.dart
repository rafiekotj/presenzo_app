import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      cursorColor: AppColor.textHint,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColor.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.all(12),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppColor.error;
          }
          if (states.contains(WidgetState.focused)) {
            return AppColor.secondary;
          }
          return AppColor.textHint;
        }),
        suffixIcon: suffixIcon,
        suffixIconColor: AppColor.textHint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.error),
        ),
        errorStyle: TextStyle(
          color: AppColor.error,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }
}
