import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pocketcrm/core/theme/app_colors.dart';

/// iOS-style "Slide to Execute" confirmation button.
///
/// The user must drag the thumb past 85% of the track width to trigger
/// [onExecute]. Provides progressive haptic feedback and visual states
/// for loading, success, and error.
class SlideToExecuteButton extends StatefulWidget {
  /// Async callback invoked when the user completes the slide.
  /// If the future completes normally → success state.
  /// If it throws → error state with shake animation.
  final Future<void> Function() onExecute;

  /// Whether the slider is interactive.
  final bool enabled;

  /// Text displayed inside the track.
  final String label;

  const SlideToExecuteButton({
    super.key,
    required this.onExecute,
    this.enabled = true,
    this.label = 'Slide to execute',
  });

  @override
  State<SlideToExecuteButton> createState() => _SlideToExecuteButtonState();
}

enum _SlideState { idle, dragging, loading, success, error }

class _SlideToExecuteButtonState extends State<SlideToExecuteButton>
    with SingleTickerProviderStateMixin {
  _SlideState _state = _SlideState.idle;
  double _dragPosition = 0;

  // Track which haptic thresholds have been triggered during this drag
  final Set<int> _hapticThresholds = {};

  // Shake animation controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const double _trackHeight = 62;
  static const double _thumbSize = 52;
  static const double _trackPadding = 5;
  static const double _activationThreshold = 0.85;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double get _maxDrag {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 200;
    return renderBox.size.width - _thumbSize - (_trackPadding * 2);
  }

  double get _progress => (_maxDrag > 0) ? (_dragPosition / _maxDrag).clamp(0.0, 1.0) : 0.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_state != _SlideState.idle && _state != _SlideState.dragging) return;
    if (!widget.enabled) return;

    setState(() {
      _state = _SlideState.dragging;
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, _maxDrag);
    });

    // Progressive haptic feedback at 25%, 50%, 75%
    final pct = (_progress * 100).round();
    for (final threshold in [25, 50, 75]) {
      if (pct >= threshold && !_hapticThresholds.contains(threshold)) {
        _hapticThresholds.add(threshold);
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_state != _SlideState.dragging) return;

    _hapticThresholds.clear();

    if (_progress >= _activationThreshold) {
      _execute();
    } else {
      _resetThumb();
    }
  }

  void _resetThumb() {
    setState(() {
      _state = _SlideState.idle;
      _dragPosition = 0;
    });
  }

  void _announce(String message) {
    if (!mounted) return;
    try {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      );
    } catch (_) {}
  }

  Future<void> _execute() async {
    setState(() {
      _state = _SlideState.loading;
      _dragPosition = _maxDrag; // Snap to end
    });
    _announce('Executing workflow');

    try {
      await widget.onExecute();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _announce('Workflow executed successfully');
      setState(() => _state = _SlideState.success);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _announce('Failed to execute workflow');
      setState(() => _state = _SlideState.error);
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _resetThumb();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final successColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
    final errorColor = isDark ? AppColors.darkError : AppColors.lightError;
    final surfaceColor = isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    final accessibleNavigation = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    if (accessibleNavigation) {
      String buttonText;
      Widget icon;
      VoidCallback? onPressed;

      switch (_state) {
        case _SlideState.loading:
          buttonText = 'Executing...';
          icon = const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
          onPressed = null;
          break;
        case _SlideState.success:
          buttonText = 'Done!';
          icon = const Icon(Icons.check_circle_rounded, color: Colors.white);
          onPressed = null;
          break;
        case _SlideState.error:
          buttonText = 'Execution failed. Tap to retry';
          icon = const Icon(Icons.error_outline_rounded, color: Colors.white);
          onPressed = widget.enabled ? _execute : null;
          break;
        default:
          buttonText = widget.label;
          icon = const Icon(Icons.play_arrow_rounded, color: Colors.white);
          onPressed = widget.enabled ? _execute : null;
      }

      Color btnBgColor;
      if (_state == _SlideState.success) {
        btnBgColor = successColor;
      } else if (_state == _SlideState.error) {
        btnBgColor = errorColor;
      } else {
        btnBgColor = widget.enabled ? primaryColor : primaryColor.withValues(alpha: 0.4);
      }

      return SizedBox(
        width: double.infinity,
        height: _trackHeight,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(
            buttonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: btnBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
            ),
          ),
        ),
      );
    }

    Color trackColor;
    Color thumbColor;
    switch (_state) {
      case _SlideState.success:
        trackColor = successColor.withValues(alpha: 0.2);
        thumbColor = successColor;
        break;
      case _SlideState.error:
        trackColor = errorColor.withValues(alpha: 0.15);
        thumbColor = errorColor;
        break;
      default:
        trackColor = surfaceColor;
        thumbColor = widget.enabled ? primaryColor : primaryColor.withValues(alpha: 0.4);
    }

    final sliderWidget = AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        double shakeOffset = 0;
        if (_state == _SlideState.error && _shakeController.isAnimating) {
          shakeOffset = sin(_shakeAnimation.value * pi * 3) * 8;
        }

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(_trackHeight / 2),
          border: Border.all(
            color: _state == _SlideState.error
                ? errorColor.withValues(alpha: 0.5)
                : borderColor,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track label
            if (_state != _SlideState.success)
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: _state == _SlideState.loading
                      ? 0.0
                      : (1.0 - _progress).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.enabled
                              ? textColor
                              : textColor.withValues(alpha: 0.3),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: widget.enabled
                            ? textColor
                            : textColor.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),

            // Success label
            if (_state == _SlideState.success)
              Center(
                child: Text(
                  'Done!',
                  style: TextStyle(
                    color: successColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Thumb
            AnimatedPositioned(
              duration: _state == _SlideState.dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: _trackPadding + _dragPosition,
              top: _trackPadding,
              child: GestureDetector(
                onHorizontalDragUpdate:
                    widget.enabled ? _onDragUpdate : null,
                onHorizontalDragEnd:
                    widget.enabled ? _onDragEnd : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: thumbColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildThumbContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled && _state != _SlideState.loading && _state != _SlideState.success,
      label: widget.label,
      hint: 'Double tap to execute, or slide horizontally',
      onTap: widget.enabled && _state != _SlideState.loading && _state != _SlideState.success
          ? _execute
          : null,
      child: sliderWidget,
    );
  }

  Widget _buildThumbContent() {
    switch (_state) {
      case _SlideState.loading:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      case _SlideState.success:
        return const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 26,
        );
      case _SlideState.error:
        return const Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: 26,
        );
      default:
        return const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 26,
        );
    }
  }
}
