import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance optimization utilities for animations
class AnimationPerformance {
  /// Check if animations should be reduced based on system settings
  static bool get shouldReduceAnimations {
    return WidgetsBinding.instance.platformDispatcher.views.first
        .platformDispatcher.accessibilityFeatures.accessibleNavigation;
  }

  /// Get appropriate duration based on system settings
  static Duration getOptimizedDuration(Duration baseDuration) {
    if (shouldReduceAnimations) {
      return Duration(
          milliseconds: (baseDuration.inMilliseconds * 0.5).round());
    }
    return baseDuration;
  }

  /// Check if device can handle complex animations
  static bool get canHandleComplexAnimations {
    // Check device performance capabilities
    final scheduler = SchedulerBinding.instance;
    return !scheduler.schedulerPhase.toString().contains('idle');
  }

  /// Optimize animation curve based on performance
  static Curve getOptimizedCurve(Curve baseCurve) {
    if (shouldReduceAnimations) {
      return Curves.linear;
    }
    return baseCurve;
  }

  /// Memory-efficient animation controller
  static AnimationController createOptimizedController(
    TickerProvider vsync, {
    Duration? duration,
    Duration? reverseDuration,
    double? lowerBound,
    double? upperBound,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    return AnimationController(
      duration: duration != null ? getOptimizedDuration(duration) : null,
      reverseDuration: reverseDuration != null
          ? getOptimizedDuration(reverseDuration)
          : null,
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior,
      vsync: vsync,
    );
  }

  /// Dispose animation controllers safely
  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.dispose();
    }
  }

  /// Check if widget is still mounted before animation
  static void safeAnimate(
    AnimationController controller,
    State widget, {
    required VoidCallback animation,
  }) {
    if (widget.mounted) {
      animation();
    }
  }
}

/// Performance-optimized animation widget
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final VoidCallback? onAnimationComplete;

  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.enabled = true,
    this.onAnimationComplete,
  });

  @override
  State<OptimizedAnimatedWidget> createState() =>
      _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationPerformance.createOptimizedController(
      this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationPerformance.getOptimizedCurve(widget.curve),
    ));

    if (widget.enabled) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(OptimizedAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Memory-efficient list animation
class OptimizedListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final bool enabled;

  const OptimizedListAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.enabled = true,
  });

  @override
  State<OptimizedListAnimation> createState() => _OptimizedListAnimationState();
}

class _OptimizedListAnimationState extends State<OptimizedListAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.enabled) {
      _startAnimations();
    }
  }

  void _setupAnimations() {
    _controllers = widget.children.asMap().entries.map((entry) {
      return AnimationPerformance.createOptimizedController(
        this,
        duration: widget.itemDuration,
      );
    }).toList();

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: AnimationPerformance.getOptimizedCurve(widget.curve),
      ));
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
          Duration(milliseconds: i * widget.staggerDelay.inMilliseconds), () {
        AnimationPerformance.safeAnimate(
          _controllers[i],
          this,
          animation: () => _controllers[i].forward(),
        );
      });
    }
  }

  @override
  void didUpdateWidget(OptimizedListAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _startAnimations();
      } else {
        for (final controller in _controllers) {
          controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    AnimationPerformance.disposeControllers(_controllers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, _) {
            return Transform.translate(
              offset: Offset(0, (1 - _animations[index].value) * 20),
              child: Opacity(
                opacity: _animations[index].value,
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Performance monitoring for animations
class AnimationPerformanceMonitor {
  static final Map<String, int> _animationCounts = {};
  static final Map<String, Duration> _animationDurations = {};

  /// Track animation performance
  static void trackAnimation(String animationName, Duration duration) {
    _animationCounts[animationName] =
        (_animationCounts[animationName] ?? 0) + 1;
    _animationDurations[animationName] = duration;
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'animationCounts': Map.from(_animationCounts),
      'animationDurations': _animationDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
    };
  }

  /// Clear performance data
  static void clearStats() {
    _animationCounts.clear();
    _animationDurations.clear();
  }

  /// Check if too many animations are running
  static bool get isOverloaded {
    final totalAnimations =
        _animationCounts.values.fold(0, (sum, count) => sum + count);
    return totalAnimations > 50; // Threshold for performance
  }
}

/// Animation quality settings based on device capabilities
class AnimationQuality {
  static AnimationQualityLevel _currentLevel = AnimationQualityLevel.high;

  static AnimationQualityLevel get currentLevel => _currentLevel;

  static void setQualityLevel(AnimationQualityLevel level) {
    _currentLevel = level;
  }

  static Duration getDuration(Duration baseDuration) {
    switch (_currentLevel) {
      case AnimationQualityLevel.low:
        return Duration(
            milliseconds: (baseDuration.inMilliseconds * 0.3).round());
      case AnimationQualityLevel.medium:
        return Duration(
            milliseconds: (baseDuration.inMilliseconds * 0.6).round());
      case AnimationQualityLevel.high:
        return baseDuration;
    }
  }

  static Curve getCurve(Curve baseCurve) {
    switch (_currentLevel) {
      case AnimationQualityLevel.low:
        return Curves.linear;
      case AnimationQualityLevel.medium:
        return Curves.easeInOut;
      case AnimationQualityLevel.high:
        return baseCurve;
    }
  }

  static bool get shouldUseComplexAnimations {
    return _currentLevel == AnimationQualityLevel.high;
  }
}

enum AnimationQualityLevel {
  low,
  medium,
  high,
}
