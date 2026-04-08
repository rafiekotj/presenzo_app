import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final bool? enableSuggestions;
  final bool? autocorrect;
  final String? Function(String?)? validator;
  final EdgeInsets? errorPadding;

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
    this.errorPadding,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  // Menentukan apakah label harus berada pada posisi floating.
  bool get _isFloating {
    final text = widget.controller?.text.trim() ?? '';
    return _focusNode.hasFocus || text.isNotEmpty;
  }

  // Menyiapkan listener focus dan listener perubahan teks saat widget dibuat.
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller?.addListener(_handleTextChange);
  }

  // Menukar listener ketika instance controller dari parent berubah.
  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      widget.controller?.addListener(_handleTextChange);
    }
  }

  // Merender ulang UI jika widget masih aktif.
  void _refreshUI() {
    if (!mounted) return;
    setState(() {});
  }

  // Menangani perubahan fokus untuk menggerakkan animasi label.
  void _handleFocusChange() {
    _refreshUI();
  }

  // Menangani perubahan teks agar status floating label selalu akurat.
  void _handleTextChange() {
    _refreshUI();
  }

  // Menentukan warna border, label, dan ikon berdasarkan state field.
  Color _stateColor({
    required bool hasError,
    required Color focusColor,
    required Color normalColor,
  }) {
    if (hasError) return AppColor.error;
    if (_focusNode.hasFocus) return focusColor;
    return normalColor;
  }

  // Menentukan posisi horizontal label dan area input.
  double _contentLeftPadding() {
    return widget.prefixIcon != null ? 44 : 12;
  }

  // Menentukan posisi horizontal suffix icon.
  double _contentRightPadding() {
    return widget.suffixIcon != null ? 44 : 12;
  }

  // Menentukan padding input sesuai kondisi label floating.
  EdgeInsets _inputPadding(bool floatLabel) {
    return EdgeInsets.only(
      left: _contentLeftPadding(),
      right: _contentRightPadding(),
      top: floatLabel ? 17 : 14,
      bottom: floatLabel ? 11 : 14,
    );
  }

  // Menjalankan validator eksternal dan menyimpan hasil error ke state.
  String? _runValidation(String? value) {
    final error = widget.validator?.call(value);
    if (mounted) {
      setState(() {
        _errorText = error;
      });
    }
    return error;
  }

  // Membersihkan listener dan focus node saat widget dibuang.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceText = theme.colorScheme.onSurface;
    final hintColor = isDark ? const Color(0xFF86AAA2) : AppColor.textHint;
    final fillColor = isDark ? const Color(0xFF1A3A33) : AppColor.fieldFill;

    final floatLabel = _isFloating;
    final hasError = _errorText != null && _errorText!.isNotEmpty;
    final borderColor = _stateColor(
      hasError: hasError,
      focusColor: AppColor.secondary,
      normalColor: hintColor,
    );
    final labelColor = _stateColor(
      hasError: hasError,
      focusColor: AppColor.secondary,
      normalColor: hintColor,
    );
    final iconColor = _stateColor(
      hasError: hasError,
      focusColor: AppColor.primary,
      normalColor: hintColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: _contentLeftPadding(),
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
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: _inputPadding(floatLabel),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 28,
                          child: TextFormField(
                            focusNode: _focusNode,
                            controller: widget.controller,
                            cursorColor: hintColor,
                            cursorHeight: 20,
                            obscureText: widget.obscureText,
                            obscuringCharacter: '•',
                            readOnly: widget.readOnly,
                            keyboardType: widget.keyboardType,
                            enableSuggestions:
                                widget.enableSuggestions ?? !widget.obscureText,
                            autocorrect:
                                widget.autocorrect ?? !widget.obscureText,
                            smartDashesType: SmartDashesType.disabled,
                            smartQuotesType: SmartQuotesType.disabled,
                            textAlignVertical: TextAlignVertical.center,
                            strutStyle: const StrutStyle(
                              fontSize: 14,
                              height: 1.2,
                              forceStrutHeight: true,
                            ),
                            style: TextStyle(
                              color: surfaceText,
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
                            validator: (value) {
                              _runValidation(value);
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.suffixIcon != null)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: SizedBox(
                        height: 28,
                        child: IconTheme(
                          data: IconThemeData(color: hintColor),
                          child: Center(child: widget.suffixIcon!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_errorText != null && _errorText!.isNotEmpty)
          Padding(
            padding:
                widget.errorPadding ?? const EdgeInsets.only(top: 6, left: 4),
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
    );
  }
}
