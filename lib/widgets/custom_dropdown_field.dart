import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

/// CustomDropdownField - Dropdown dengan floating label dan prefix icon
/// Features:
/// - Floating label yang animasi naik saat focus/ada pilihan
/// - Icon prefix tetap stabil (tidak bergerak saat focus)
/// - Dropdown menu dengan styling
/// - Total height konsisten: 28px (padding top+bottom)
/// - Dynamic menu width (sesuai field width)
class CustomDropdownField<TValue> extends StatefulWidget {
  // ==================== PROPERTIES ====================
  final TValue? selectedValue; // nilai yang dipilih
  final String hintText; // text untuk label & placeholder
  final IconData prefixIcon; // icon di sebelah kiri
  final List<DropdownMenuItem<TValue>> items; // list pilihan
  final ValueChanged<TValue?>? onChanged; // callback saat pilihan berubah
  final String? Function(TValue?)? validator; // validasi
  final bool isRequired; // jika true, harus dipilih (otomatis validasi)
  final bool isLoading; // loading state
  final String loadingText; // text saat loading
  final double menuMaxHeight; // max tinggi dropdown menu
  final Color dropdownColor; // background color menu

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
  // ==================== STATE VARIABLES ====================
  late final ValueNotifier<TValue?> _selectedValueNotifier; // reactive state
  final GlobalKey _fieldContainerKey = GlobalKey(); // untuk mengukur width
  final FocusNode _focusNode = FocusNode(); // track focus state
  String? _errorText; // error message
  double? _menuWidth; // dropdown menu width (same as field)
  bool _hasInteracted = false; // track apakah user sudah interact

  @override
  void initState() {
    super.initState();
    _selectedValueNotifier = ValueNotifier<TValue?>(widget.selectedValue);
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMenuWidth();
    });
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
      // Mark sebagai sudah interact saat focus
      if (_focusNode.hasFocus && !_hasInteracted) {
        _hasInteracted = true;
      }
      // Auto-validate saat focus hilang (hanya jika sudah interact)
      if (!_focusNode.hasFocus &&
          _hasInteracted &&
          (widget.validator != null || widget.isRequired)) {
        setState(() {
          if (widget.validator != null) {
            _errorText = widget.validator?.call(_selectedValueNotifier.value);
          } else if (widget.isRequired &&
              _selectedValueNotifier.value == null) {
            _errorText = "Harus dipilih";
          } else {
            _errorText = null;
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(CustomDropdownField<TValue> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _selectedValueNotifier.value = widget.selectedValue;
    }
    // Hapus error dan reset interaction flag saat loading selesai
    if (oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _errorText = null;
        _hasInteracted = false;
      });
    }
    // Hapus error saat items berubah
    if (oldWidget.items.length != widget.items.length) {
      setState(() {
        _errorText = null;
      });
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
    // Update selected value, validasi, dan trigger callback
    _selectedValueNotifier.value = value;
    _hasInteracted = true; // Mark sebagai sudah interact
    setState(() {
      // Validasi dengan custom validator atau isRequired (hanya jika sudah interact)
      if (_hasInteracted) {
        if (widget.validator != null) {
          _errorText = widget.validator?.call(value);
        } else if (widget.isRequired && value == null) {
          _errorText = "Harus dipilih";
        } else {
          _errorText = null;
        }
      }
    });
    widget.onChanged?.call(value);
  }

  /// Public method untuk validasi - bisa dipanggil dari parent widget
  /// Gunakan saat form submission untuk validasi semua field
  String? validate() {
    _hasInteracted = true; // Mark sebagai sudah interact saat submit
    String? error;
    if (widget.validator != null) {
      error = widget.validator?.call(_selectedValueNotifier.value);
    } else if (widget.isRequired && _selectedValueNotifier.value == null) {
      error = "Harus dipilih";
    }
    setState(() {
      _errorText = error;
    });
    return error;
  }

  @override
  void dispose() {
    _selectedValueNotifier.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

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

  // ==================== BUILD METHOD ====================
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

    // ==================== SETUP VARIABLES ====================
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

    // Cek apakah dropdown harus floating (focus atau ada value)
    final isFloating =
        _focusNode.hasFocus || _selectedValueNotifier.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==================== GESTURE DETECTOR ====================
        // Membuat seluruh area field bisa diklik untuk trigger dropdown
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            setState(() {});
          },
          child: Container(
            key: _fieldContainerKey, // untuk mengukur width field
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
                // ==================== FLOATING LABEL ====================
                // Label yang animasi naik dari top:17 (unfocus) -> top:4 (focus)
                // Juga berubah ukuran: 14 -> 11 dan warna berubah follow focus
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
                // ==================== PREFIX ICON ====================
                // Icon di sebelah kiri - FIXED position (tidak bergerak saat focus)
                // top: 14 konsisten untuk centering icon vertikal
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
                  // ==================== DROPDOWN BUTTON AREA ====================
                  // Padding: 28px total height = top (17 or 14) + bottom (11 or 14)
                  // - Saat focus: top:17 + bottom:11 = 28px
                  // - Saat unfocus: top:14 + bottom:14 = 28px (konsisten!)
                  // Left: 44px (untuk icon), Right: 12px
                  child: Row(
                    children: [
                      Expanded(
                        // ==================== DROPDOWN BUTTON ====================
                        // Custom dropdown dengan styling:
                        // - height: 28 (disamakan dengan text field)
                        // - underline: none (styling di outer container)
                        // - menuMaxHeight: configurable (default 280)
                        // - menu width: same as field width
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
                              boxShadow: Theme.of(context).brightness == Brightness.dark ? const [] : [
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

