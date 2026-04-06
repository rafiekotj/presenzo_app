import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

/// CustomTextField - Text input dengan floating label dan prefix/suffix icon
/// Features:
/// - Floating label yang animasi naik saat focus/ada text
/// - Icon prefix tetap stabil (tidak bergerak saat focus)
/// - Icon suffix (opsional)
/// - Cursor lebih tinggi dan visible
/// - Total height konsisten: 28px (padding top+bottom)
class CustomTextField extends StatefulWidget {
  // ==================== PROPERTIES ====================
  final TextEditingController? controller;
  final String hintText; // text untuk label & placeholder
  final IconData? prefixIcon; // icon di sebelah kiri
  final Widget? suffixIcon; // icon di sebelah kanan
  final bool obscureText; // untuk password field
  final bool readOnly;
  final TextInputType? keyboardType;
  final bool? enableSuggestions;
  final bool? autocorrect;
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
    this.enableSuggestions,
    this.autocorrect,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();

  // ==================== FLOATING LABEL LOGIC ====================
  /// Cek apakah label harus float ke atas
  /// Kondisi: saat focus ATAU ada text yang diinput
  bool get _isFloating {
    final text = widget.controller?.text.trim() ?? '';
    return _focusNode.hasFocus || text.isNotEmpty;
  }

  // ==================== LIFECYCLE METHODS ====================
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      widget.controller?.addListener(_handleTextChange);
    }
  }

  void _handleFocusChange() {
    // Trigger rebuild saat focus berubah (untuk animasi label)
    setState(() {});
  }

  void _handleTextChange() {
    // Trigger rebuild saat text berubah (untuk floating label logic)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floatLabel = _isFloating;
    final borderColor = _focusNode.hasFocus
        ? AppColor.secondary
        : AppColor.textHint;
    final labelColor = _focusNode.hasFocus
        ? AppColor.secondary
        : AppColor.textHint;

    // ==================== GESTURE DETECTOR ====================
    // Membuat seluruh area field bisa diklik untuk trigger focus
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Container(
        // ==================== CONTAINER & BORDER ====================
        // Background field dengan border yang berubah saat focus
        decoration: BoxDecoration(
          color: AppColor.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================== FLOATING LABEL ====================
            // Label yang animasi naik dari top:20 (unfocus) -> top:4 (focus)
            // Juga berubah ukuran: 14 -> 11 dan warna berubah follow focus
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: 44,
              top: floatLabel ? 10 : 20,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: labelColor,
                  fontSize: floatLabel ? 11 : 14,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(widget.hintText),
              ),
            ),
            // ==================== PREFIX ICON ====================
            // Icon di sebelah kiri - FIXED position (tidak bergerak saat focus)
            // Warna icon: textHint (normal) -> primary (focus)
            // Positioned top:0 bottom:0 membuat icon selalu center vertikal
            if (widget.prefixIcon != null)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    height: 28,
                    child: Center(
                      child: Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _focusNode.hasFocus
                            ? AppColor.primary
                            : AppColor.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            // ==================== INPUT AREA ====================
            // Padding: 28px total height = top (17 or 14) + bottom (11 or 14)
            // - Saat focus: top:17 + bottom:11 = 28px
            // - Saat unfocus: top:14 + bottom:14 = 28px (konsisten!)
            // Left: 44px jika ada icon, 12px jika tidak
            Padding(
              padding: EdgeInsets.only(
                left: widget.prefixIcon != null ? 44 : 12,
                right: widget.suffixIcon != null ? 44 : 12,
                top: floatLabel ? 17 : 14,
                bottom: floatLabel ? 11 : 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    // ==================== TEXTFORMFIELD ====================
                    // Text input utama dengan styling:
                    // - cursorHeight: 20 (lebih tinggi & visible)
                    // - height: 1.4 (line height untuk spacing teks)
                    // - textAlignVertical: center (vertikal center)
                    // - Border: none (styling dilakukan di outer container)
                    child: SizedBox(
                      height: 28,
                      child: TextFormField(
                        focusNode: _focusNode,
                        controller: widget.controller,
                        cursorColor: AppColor.textHint,
                        cursorHeight: 20,
                        obscureText: widget.obscureText,
                        obscuringCharacter: '•',
                        readOnly: widget.readOnly,
                        keyboardType: widget.keyboardType,
                        enableSuggestions:
                            widget.enableSuggestions ?? !widget.obscureText,
                        autocorrect: widget.autocorrect ?? !widget.obscureText,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        textAlignVertical: TextAlignVertical.center,
                        strutStyle: const StrutStyle(
                          fontSize: 14,
                          height: 1.2,
                          forceStrutHeight: true,
                        ),
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8),
                          counterText: '',
                        ),
                        validator: widget.validator,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ==================== SUFFIX ICON ====================
            // Dibuat FIXED position seperti prefix agar tidak ikut geser saat focus/unfocus
            if (widget.suffixIcon != null)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    height: 28,
                    child: IconTheme(
                      data: const IconThemeData(color: AppColor.textHint),
                      child: Center(child: widget.suffixIcon!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
