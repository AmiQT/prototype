import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized animation system for consistent animations across the app
class AnimationSystem {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation curves
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve smoothIn = Curves.easeInOut;
  static const Curve quickOut = Curves.easeOut;
  static const Curve springIn = Curves.elasticOut;
  static const Curve slideIn = Curves.easeOutCubic;

  // Standard animation values
  static const double scalePressed = 0.95;
  static const double scaleHover = 1.02;
  static const double fadeInStart = 0.0;
  static const double fadeInEnd = 1.0;
  static const double slideOffset = 50.0;

  /// Create a scale animation controller
  static AnimationController createScaleController(
    TickerProvider vsync, {
    Duration duration = normal,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Create a fade animation controller
  static AnimationController createFadeController(
    TickerProvider vsync, {
    Duration duration = normal,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Create a slide animation controller
  static AnimationController createSlideController(
    TickerProvider vsync, {
    Duration duration = normal,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Standard scale animation
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 1.0,
    double end = scalePressed,
    Curve curve = smoothIn,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Standard fade animation
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = fadeInStart,
    double end = fadeInEnd,
    Curve curve = smoothIn,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Standard slide animation
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, slideOffset),
    Offset end = Offset.zero,
    Curve curve = slideIn,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Staggered animation for lists
  static Animation<double> createStaggeredAnimation(
    AnimationController controller,
    int index, {
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final delay = index * staggerDelay.inMilliseconds;
    final totalDuration = controller.duration!.inMilliseconds;
    final startTime = delay / totalDuration;
    final endTime = 1.0;

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(
        startTime.clamp(0.0, 1.0),
        endTime,
        curve: smoothIn,
      ),
    ));
  }

  /// Haptic feedback helper
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}

/// Animation presets for common use cases
class AnimationPresets {
  /// Button press animation
  static Widget scaleOnPress({
    required Widget child,
    required VoidCallback? onPressed,
    double scale = AnimationSystem.scalePressed,
    Duration duration = AnimationSystem.fast,
    VoidCallback? onTapDown,
    VoidCallback? onTapUp,
  }) {
    return _ScaleOnPressWidget(
      scale: scale,
      duration: duration,
      onPressed: onPressed,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      child: child,
    );
  }

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = AnimationSystem.normal,
    Duration delay = Duration.zero,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return _FadeInWidget(
      duration: duration,
      delay: delay,
      curve: curve,
      child: child,
    );
  }

  /// Slide in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = AnimationSystem.normal,
    Duration delay = Duration.zero,
    Offset begin = const Offset(0, 50),
    Offset end = Offset.zero,
    Curve curve = AnimationSystem.slideIn,
  }) {
    return _SlideInWidget(
      duration: duration,
      delay: delay,
      begin: begin,
      end: end,
      curve: curve,
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration itemDuration = AnimationSystem.normal,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return _StaggeredListWidget(
      children: children,
      staggerDelay: staggerDelay,
      itemDuration: itemDuration,
      curve: curve,
    );
  }

  /// Staggered slide in animation for individual items
  static Widget staggeredSlideIn({
    required Widget child,
    required int index,
    Duration duration = AnimationSystem.normal,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Offset begin = const Offset(0, 50),
    Offset end = Offset.zero,
    Curve curve = AnimationSystem.slideIn,
  }) {
    return _StaggeredSlideInWidget(
      duration: duration,
      delay: Duration(milliseconds: index * staggerDelay.inMilliseconds),
      begin: begin,
      end: end,
      curve: curve,
      child: child,
    );
  }

  /// Shake animation
  static Widget shake({
    required Widget child,
    Duration duration = AnimationSystem.normal,
    Duration delay = Duration.zero,
    double intensity = 10.0,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return _ShakeWidget(
      duration: duration,
      delay: delay,
      intensity: intensity,
      curve: curve,
      child: child,
    );
  }

  /// Bounce in animation
  static Widget bounceIn({
    required Widget child,
    Duration duration = AnimationSystem.normal,
    Duration delay = Duration.zero,
    double scale = 1.2,
    Curve curve = AnimationSystem.bounceIn,
  }) {
    return _BounceInWidget(
      duration: duration,
      delay: delay,
      scale: scale,
      curve: curve,
      child: child,
    );
  }
}

/// Scale on press widget implementation
class _ScaleOnPressWidget extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final VoidCallback? onPressed;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const _ScaleOnPressWidget({
    required this.child,
    required this.scale,
    required this.duration,
    this.onPressed,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  State<_ScaleOnPressWidget> createState() => _ScaleOnPressWidgetState();
}

class _ScaleOnPressWidgetState extends State<_ScaleOnPressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = AnimationSystem.createScaleAnimation(
      _controller,
      end: widget.scale,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      widget.onTapDown?.call();
      AnimationSystem.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    _controller.reverse();
    widget.onTapUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Fade in widget implementation
class _FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const _FadeInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
  });

  @override
  State<_FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<_FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = AnimationSystem.createFadeAnimation(
      _controller,
      curve: widget.curve,
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Slide in widget implementation
class _SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  final Offset end;
  final Curve curve;

  const _SlideInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.begin,
    required this.end,
    required this.curve,
  });

  @override
  State<_SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<_SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _slideAnimation = AnimationSystem.createSlideAnimation(
      _controller,
      begin: widget.begin,
      end: widget.end,
      curve: widget.curve,
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered list widget implementation
class _StaggeredListWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;

  const _StaggeredListWidget({
    required this.children,
    required this.staggerDelay,
    required this.itemDuration,
    required this.curve,
  });

  @override
  State<_StaggeredListWidget> createState() => _StaggeredListWidgetState();
}

class _StaggeredListWidgetState extends State<_StaggeredListWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.itemDuration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return AnimationPresets.slideIn(
          delay: Duration(
              milliseconds: index * widget.staggerDelay.inMilliseconds),
          duration: widget.itemDuration,
          curve: widget.curve,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Staggered slide in widget implementation
class _StaggeredSlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  final Offset end;
  final Curve curve;

  const _StaggeredSlideInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.begin,
    required this.end,
    required this.curve,
  });

  @override
  State<_StaggeredSlideInWidget> createState() =>
      _StaggeredSlideInWidgetState();
}

class _StaggeredSlideInWidgetState extends State<_StaggeredSlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
      },
    );
  }
}

/// Shake widget implementation
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double intensity;
  final Curve curve;

  const _ShakeWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.intensity,
    required this.curve,
  });

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: widget.intensity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              _shakeAnimation.value *
                  (0.5 - (DateTime.now().millisecondsSinceEpoch % 2)),
              0),
          child: widget.child,
        );
      },
    );
  }
}

/// Bounce in widget implementation
class _BounceInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double scale;
  final Curve curve;

  const _BounceInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.scale,
    required this.curve,
  });

  @override
  State<_BounceInWidget> createState() => _BounceInWidgetState();
}

class _BounceInWidgetState extends State<_BounceInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
