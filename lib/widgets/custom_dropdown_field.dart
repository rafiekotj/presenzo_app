import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

class CustomDropdownField<TValue> extends StatelessWidget {
  final TValue? selectedValue;
  final String hintText;
  final IconData prefixIcon;
  final List<DropdownMenuItem<TValue>> items;
  final ValueChanged<TValue?>? onChanged;
  final String? Function(TValue?)? validator;
  final bool isLoading;
  final String loadingText;
  final double menuMaxHeight;
  final Color dropdownColor;

  const CustomDropdownField({
    super.key,
    this.selectedValue,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    this.isLoading = false,
    this.loadingText = 'Memuat pilihan...',
    this.menuMaxHeight = 280,
    this.dropdownColor = AppColor.surface,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveItems = isLoading
        ? <DropdownMenuItem<TValue>>[
            DropdownMenuItem<TValue>(
              value: null,
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  loadingText,
                  style: const TextStyle(
                    color: AppColor.textHint,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ]
        : items;

    return DropdownButtonFormField<TValue>(
      initialValue: isLoading ? null : selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColor.fieldFill,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColor.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.all(12),
        prefixIcon: Icon(prefixIcon, size: 20),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColor.secondary;
          }
          if (states.contains(WidgetState.error)) {
            return AppColor.error;
          }
          return AppColor.textHint;
        }),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColor.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColor.secondary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColor.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColor.error),
        ),
        errorStyle: const TextStyle(
          color: AppColor.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      hint: Text(
        hintText,
        style: const TextStyle(
          color: AppColor.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      menuMaxHeight: menuMaxHeight,
      dropdownColor: dropdownColor,
      style: const TextStyle(
        color: AppColor.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      items: effectiveItems,
      onChanged: isLoading ? null : onChanged,
      validator: validator,
    );
  }
}
