import 'package:flutter/material.dart';
import '../../utils/animation_system.dart';

/// Collection of engaging loading animations
class LoadingAnimations {
  /// Pulsing dot loading animation
  static Widget pulsingDots({
    Color color = Colors.blue,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return _PulsingDotsWidget(
      color: color,
      size: size,
      duration: duration,
    );
  }

  /// Bouncing dots loading animation
  static Widget bouncingDots({
    Color color = Colors.blue,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return _BouncingDotsWidget(
      color: color,
      size: size,
      duration: duration,
    );
  }

  /// Rotating circle loading animation
  static Widget rotatingCircle({
    Color color = Colors.blue,
    double size = 40.0,
    double strokeWidth = 4.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return _RotatingCircleWidget(
      color: color,
      size: size,
      strokeWidth: strokeWidth,
      duration: duration,
    );
  }

  /// Skeleton loading for cards
  static Widget skeletonCard({
    double height = 120.0,
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    return _SkeletonCardWidget(
      height: height,
      padding: padding,
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerWidget(
      child: child,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
    );
  }

  /// Progress bar with animation
  static Widget animatedProgressBar({
    required double progress,
    Color backgroundColor = const Color(0xFFE0E0E0),
    Color progressColor = Colors.blue,
    double height = 4.0,
    Duration duration = AnimationSystem.normal,
  }) {
    return _AnimatedProgressBarWidget(
      progress: progress,
      backgroundColor: backgroundColor,
      progressColor: progressColor,
      height: height,
      duration: duration,
    );
  }

  /// Loading overlay with blur
  static Widget loadingOverlay({
    required Widget child,
    required bool isLoading,
    String? loadingText,
    Color overlayColor = Colors.black54,
  }) {
    return _LoadingOverlayWidget(
      child: child,
      isLoading: isLoading,
      loadingText: loadingText,
      overlayColor: overlayColor,
    );
  }
}

/// Pulsing dots implementation
class _PulsingDotsWidget extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _PulsingDotsWidget({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_PulsingDotsWidget> createState() => _PulsingDotsWidgetState();
}

class _PulsingDotsWidgetState extends State<_PulsingDotsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Bouncing dots implementation
class _BouncingDotsWidget extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const _BouncingDotsWidget({
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_BouncingDotsWidget> createState() => _BouncingDotsWidgetState();
}

class _BouncingDotsWidgetState extends State<_BouncingDotsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animations[index].value * 10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Rotating circle implementation
class _RotatingCircleWidget extends StatefulWidget {
  final Color color;
  final double size;
  final double strokeWidth;
  final Duration duration;

  const _RotatingCircleWidget({
    required this.color,
    required this.size,
    required this.strokeWidth,
    required this.duration,
  });

  @override
  State<_RotatingCircleWidget> createState() => _RotatingCircleWidgetState();
}

class _RotatingCircleWidgetState extends State<_RotatingCircleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.repeat();
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
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card implementation
class _SkeletonCardWidget extends StatefulWidget {
  final double height;
  final EdgeInsets padding;

  const _SkeletonCardWidget({
    required this.height,
    required this.padding,
  });

  @override
  State<_SkeletonCardWidget> createState() => _SkeletonCardWidgetState();
}

class _SkeletonCardWidgetState extends State<_SkeletonCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                colors: const [
                  Color(0xFFE0E0E0),
                  Color(0xFFF5F5F5),
                  Color(0xFFE0E0E0),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer effect implementation
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const _ShimmerWidget({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animated progress bar implementation
class _AnimatedProgressBarWidget extends StatefulWidget {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double height;
  final Duration duration;

  const _AnimatedProgressBarWidget({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.height,
    required this.duration,
  });

  @override
  State<_AnimatedProgressBarWidget> createState() =>
      _AnimatedProgressBarWidgetState();
}

class _AnimatedProgressBarWidgetState extends State<_AnimatedProgressBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.progressColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loading overlay implementation
class _LoadingOverlayWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color overlayColor;

  const _LoadingOverlayWidget({
    required this.child,
    required this.isLoading,
    this.loadingText,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimations.rotatingCircle(
                    color: Colors.white,
                    size: 50,
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      loadingText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
