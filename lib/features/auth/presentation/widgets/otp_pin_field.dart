/// Six-digit OTP pin input with paste and auto-complete support.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class OtpPinField extends StatefulWidget {
  const OtpPinField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = false,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool hasError;
  final bool autofocus;

  @override
  State<OtpPinField> createState() => OtpPinFieldState();
}

class OtpPinFieldState extends State<OtpPinField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    widget.onChanged?.call('');
    if (mounted) setState(() {});
  }

  void _handleChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      _controller.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    widget.onChanged?.call(digits);
    if (digits.length == widget.length) {
      widget.onCompleted?.call(digits);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final code = _controller.text;
    final borderColor = widget.hasError
        ? cs.error
        : cs.outlineVariant.withValues(alpha: 0.55);
    final fillColor = widget.enabled
        ? cs.surfaceContainerHighest.withValues(alpha: 0.65)
        : cs.surfaceContainerHighest.withValues(alpha: 0.35);
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.authOtpInputSemantics,
      textField: true,
      enabled: widget.enabled,
      child: GestureDetector(
        onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: List.generate(widget.length, (index) {
                    final digit = index < code.length ? code[index] : '';
                    final focused =
                        widget.enabled &&
                        _focusNode.hasFocus &&
                        (index == code.length ||
                            (index == widget.length - 1 &&
                                code.length == widget.length));
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: t.space4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(t.radiusMd),
                            border: Border.all(
                              color: focused ? cs.primary : borderColor,
                              width: focused ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            digit,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 52,
                    width: constraints.maxWidth,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      textInputAction: TextInputAction.done,
                      maxLength: widget.length,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: _handleChanged,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
