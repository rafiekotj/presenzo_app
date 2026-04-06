import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

class CustomDropdownField<TValue> extends StatefulWidget {
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
  State<CustomDropdownField<TValue>> createState() =>
      _CustomDropdownFieldState<TValue>();
}

class _CustomDropdownFieldState<TValue>
    extends State<CustomDropdownField<TValue>> {
  late final ValueNotifier<TValue?> _selectedValueNotifier;
  final GlobalKey _fieldContainerKey = GlobalKey();
  String? _errorText;
  double? _menuWidth;

  @override
  void initState() {
    super.initState();
    _selectedValueNotifier = ValueNotifier<TValue?>(widget.selectedValue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMenuWidth();
    });
  }

  @override
  void didUpdateWidget(CustomDropdownField<TValue> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValueNotifier.value = widget.selectedValue;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMenuWidth();
    });
  }

  void _updateMenuWidth() {
    final context = _fieldContainerKey.currentContext;
    if (context == null) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final nextWidth = renderBox.size.width;
    if (_menuWidth == nextWidth) {
      return;
    }

    setState(() {
      _menuWidth = nextWidth;
    });
  }

  void _validateAndUpdate(TValue? value) {
    _selectedValueNotifier.value = value;
    setState(() {
      _errorText = widget.validator?.call(value);
    });
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _selectedValueNotifier.dispose();
    super.dispose();
  }

  List<DropdownItem<TValue>> _convertToDropdownItems() {
    if (widget.isLoading) {
      return <DropdownItem<TValue>>[];
    }

    return widget.items
        .map(
          (item) => DropdownItem<TValue>(
            value: item.value,
            enabled: item.enabled,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: item.child,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null && _errorText!.isNotEmpty;
    final dropdownItems = _convertToDropdownItems();
    const horizontalFieldPadding = 12.0;
    const prefixIconSize = 20.0;
    const prefixGap = 12.0;
    const dropdownYOffset = -2.0;
    const dropdownXOffset =
        -(horizontalFieldPadding + prefixIconSize + prefixGap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _fieldContainerKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColor.error : AppColor.textHint,
              width: 1,
            ),
            color: AppColor.fieldFill,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: hasError ? AppColor.error : AppColor.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton2<TValue>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: dropdownItems,
                    valueListenable: _selectedValueNotifier,
                    onChanged: widget.isLoading ? null : _validateAndUpdate,
                    buttonStyleData: ButtonStyleData(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    iconStyleData: IconStyleData(
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hasError ? AppColor.error : AppColor.textHint,
                      ),
                      iconSize: 20,
                      openMenuIcon: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: hasError ? AppColor.error : AppColor.textHint,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      width: _menuWidth,
                      isOverButton: false,
                      maxHeight: widget.menuMaxHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.dropdownColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      offset: const Offset(dropdownXOffset, dropdownYOffset),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: WidgetStateProperty.all<double>(6),
                        thumbVisibility: WidgetStateProperty.all<bool>(true),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: Text(
                      widget.isLoading ? widget.loadingText : widget.hintText,
                      style: const TextStyle(
                        color: AppColor.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColor.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
