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
  final bool isRequired;
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
    this.isRequired = false,
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
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  double? _menuWidth;
  bool _hasInteracted = false;

  // Menyiapkan nilai awal, listener fokus, dan ukuran menu saat widget dibuat.
  @override
  void initState() {
    super.initState();
    _selectedValueNotifier = ValueNotifier<TValue?>(widget.selectedValue);
    _focusNode.addListener(_handleFocusChange);
    _scheduleMenuWidthUpdate();
  }

  // Menangani perubahan fokus untuk mengatur interaksi dan validasi otomatis.
  void _handleFocusChange() {
    if (!mounted) return;

    setState(() {});

    if (_focusNode.hasFocus && !_hasInteracted) {
      _hasInteracted = true;
    }

    if (!_focusNode.hasFocus && _hasInteracted) {
      _applyValidation(_selectedValueNotifier.value, shouldValidate: true);
    }
  }

  // Menyesuaikan state internal saat properti dari parent berubah.
  @override
  void didUpdateWidget(CustomDropdownField<TValue> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValueNotifier.value = widget.selectedValue;
    }

    if (oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _errorText = null;
        _hasInteracted = false;
      });
    }

    if (oldWidget.items.length != widget.items.length) {
      setState(() {
        _errorText = null;
      });
    }

    _scheduleMenuWidthUpdate();
  }

  // Menjadwalkan pembaruan lebar menu setelah frame selesai dirender.
  void _scheduleMenuWidthUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMenuWidth();
    });
  }

  // Menyamakan lebar menu dropdown dengan lebar field.
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

  // Menjalankan validasi dengan validator custom atau aturan wajib isi.
  String? _resolveValidationError(TValue? value) {
    if (widget.validator != null) {
      return widget.validator?.call(value);
    }

    if (widget.isRequired && value == null) {
      return 'Harus dipilih';
    }

    return null;
  }

  // Menerapkan hasil validasi ke state error field.
  void _applyValidation(TValue? value, {required bool shouldValidate}) {
    setState(() {
      _errorText = shouldValidate ? _resolveValidationError(value) : null;
    });
  }

  // Memperbarui nilai dropdown, validasi, lalu memanggil callback perubahan.
  void _validateAndUpdate(TValue? value) {
    _selectedValueNotifier.value = value;
    _hasInteracted = true;
    _applyValidation(value, shouldValidate: true);
    widget.onChanged?.call(value);
  }

  // Memvalidasi field secara manual, misalnya saat submit form.
  String? validate() {
    _hasInteracted = true;
    final error = _resolveValidationError(_selectedValueNotifier.value);
    _applyValidation(_selectedValueNotifier.value, shouldValidate: true);
    return error;
  }

  // Membersihkan resource agar tidak terjadi memory leak.
  @override
  void dispose() {
    _selectedValueNotifier.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // Mengubah item bawaan Flutter menjadi format item dari dropdown_button2.
  List<DropdownItem<TValue>> _convertToDropdownItems(Color textColor) {
    if (widget.isLoading) {
      return <DropdownItem<TValue>>[];
    }

    return widget.items
        .map(
          (item) => DropdownItem<TValue>(
            value: item.value,
            enabled: item.enabled,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceText = theme.colorScheme.onSurface;
    final hintColor = isDark ? const Color(0xFF86AAA2) : AppColor.textHint;
    final fillColor = isDark ? const Color(0xFF1A3A33) : AppColor.fieldFill;
    final dropdownColor = widget.dropdownColor == AppColor.surface
        ? theme.colorScheme.surface
        : widget.dropdownColor;

    final hasError =
        _hasInteracted &&
        !widget.isLoading &&
        _errorText != null &&
        _errorText!.isNotEmpty;
    final dropdownItems = _convertToDropdownItems(surfaceText);
    const horizontalFieldPadding = 12.0;
    const prefixIconSize = 20.0;
    const prefixGap = 12.0;
    const dropdownYOffset = -15.0;
    const dropdownXOffset =
        -(horizontalFieldPadding + prefixIconSize + prefixGap - 8.0);

    final isFloating =
        _focusNode.hasFocus || _selectedValueNotifier.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            setState(() {});
          },
          child: Container(
            key: _fieldContainerKey,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? AppColor.error
                    : _focusNode.hasFocus
                    ? AppColor.secondary
                    : hintColor,
                width: 1,
              ),
              color: fillColor,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: 44,
                  top: isFloating ? 10 : 20,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: hasError
                          ? AppColor.error
                          : _focusNode.hasFocus
                          ? AppColor.secondary
                          : hintColor,
                      fontSize: isFloating ? 11 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    child: Text(widget.hintText),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 28,
                    child: Center(
                      child: Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: hasError
                            ? AppColor.error
                            : _focusNode.hasFocus
                            ? AppColor.primary
                            : hintColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 36,
                    right: 28,
                    top: isFloating ? 17 : 14,
                    bottom: isFloating ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton2<TValue>(
                          focusNode: _focusNode,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: dropdownItems,
                          valueListenable: _selectedValueNotifier,
                          onChanged: widget.isLoading
                              ? null
                              : _validateAndUpdate,
                          buttonStyleData: const ButtonStyleData(
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                            padding: EdgeInsets.only(top: 8),
                          ),
                          iconStyleData: const IconStyleData(
                            icon: SizedBox.shrink(),
                            iconSize: 0,
                            openMenuIcon: SizedBox.shrink(),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            width: _menuWidth,
                            isOverButton: false,
                            maxHeight: widget.menuMaxHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: dropdownColor,
                              boxShadow:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(26),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            offset: const Offset(
                              dropdownXOffset,
                              dropdownYOffset,
                            ),
                            scrollbarTheme: ScrollbarThemeData(
                              radius: const Radius.circular(40),
                              thickness: WidgetStateProperty.all<double>(6),
                              thumbVisibility: WidgetStateProperty.all<bool>(
                                true,
                              ),
                            ),
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isLoading)
                  Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColor.secondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 28,
                      child: Center(
                        child: Icon(
                          _focusNode.hasFocus
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: hasError
                              ? AppColor.error
                              : _focusNode.hasFocus
                              ? AppColor.primary
                              : hintColor,
                        ),
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
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColor.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
