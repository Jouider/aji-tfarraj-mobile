import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// ReferralCodeInput — expandable parrainage code field.
/// FIX: backgroundLight bg, border token, radius 14, primary 60% icon.
///      On expand: secondary border + secondary 15% shadow.
class ReferralCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final AppStrings s;
  final bool initiallyExpanded;

  const ReferralCodeInput({
    super.key,
    required this.controller,
    required this.s,
    this.initiallyExpanded = false,
  });

  @override
  State<ReferralCodeInput> createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<ReferralCodeInput> {
  late bool _isExpanded;
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: On focus/expand → secondary border + shadow
    final isActive = _isExpanded || _hasFocus;
    final borderColor = isActive ? AppColors.secondary : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        // FIX: backgroundLight bg, border token → secondary on expand
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: Offset.zero,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed header row — always visible, 52px height
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // FIX: primary 60% opacity icon, size 20
                    Icon(
                      Icons.people_outline,
                      size: 20,
                      color: AppColors.primary.withValues(alpha: 0.60),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.s.referralCodeLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // FIX: chevron textMuted, size 18
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded text input
          if (_isExpanded) ...[
            Divider(height: 1, thickness: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 2, bottom: 2),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: widget.s.referralCodeHint,
                  hintStyle: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                  counterText: '',
                  // FIX: No border inside — card border handles it
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                // FIX: textPrimary w600 letter-spacing 2
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
