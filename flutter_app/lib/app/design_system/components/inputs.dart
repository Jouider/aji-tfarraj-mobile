import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Aji Tfarraj Input Components
/// Text fields, search inputs, and form inputs
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: hasError ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          style: AppTypography.bodyLarge.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
            filled: true,
            fillColor: widget.enabled
                ? (_isFocused ? AppColors.backgroundWhite : AppColors.backgroundLight)
                : AppColors.disabled,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? AppColors.primary : AppColors.textLight,
                    size: AppSpacing.iconMd,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            border: _buildBorder(AppColors.border),
            enabledBorder: _buildBorder(AppColors.border),
            focusedBorder: _buildBorder(AppColors.primary),
            errorBorder: _buildBorder(AppColors.error),
            focusedErrorBorder: _buildBorder(AppColors.error),
            disabledBorder: _buildBorder(AppColors.disabled),
            errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
            counterText: '',
          ),
        ),
        if (widget.helperText != null && !hasError) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            widget.helperText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (hasError) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) return widget.suffix;
    if (widget.suffixIcon == null) return null;

    return GestureDetector(
      onTap: widget.onSuffixTap,
      child: Icon(
        widget.suffixIcon,
        color: _isFocused ? AppColors.primary : AppColors.textLight,
        size: AppSpacing.iconMd,
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: color, width: 1),
    );
  }
}

/// Password input with visibility toggle
class AppPasswordField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const AppPasswordField({
    super.key,
    this.label,
    this.hint = 'Enter your password',
    this.errorText,
    this.controller,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      onSuffixTap: _toggleVisibility,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
    );
  }
}

/// Search input field
class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showClear;

  const AppSearchField({
    super.key,
    this.hint = 'Search',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textLight,
            size: AppSpacing.iconMd,
          ),
          suffixIcon: showClear
              ? GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    color: AppColors.textLight,
                    size: AppSpacing.iconSm,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Phone number input with country code
class AppPhoneField extends StatelessWidget {
  final String? label;
  final String? errorText;
  final String countryCode;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCountryCodeTap;
  final String? Function(String?)? validator;

  const AppPhoneField({
    super.key,
    this.label,
    this.errorText,
    this.countryCode = '+212',
    this.controller,
    this.onChanged,
    this.onCountryCodeTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.labelMedium),
          SizedBox(height: AppSpacing.xs),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code selector
            GestureDetector(
              onTap: onCountryCodeTap,
              child: Container(
                height: AppSpacing.inputHeight,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      countryCode,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: AppSpacing.iconSm,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            // Phone number input
            Expanded(
              child: AppTextField(
                hint: '6XX XXX XXX',
                controller: controller,
                keyboardType: TextInputType.phone,
                onChanged: onChanged,
                errorText: errorText,
                validator: validator,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
