import 'package:flutter/material.dart';
import '../../utils/animation_system.dart';

/// Collection of micro-interactions for enhanced user experience
class MicroInteractions {
  /// Animated like button with heart animation
  static Widget animatedLikeButton({
    required bool isLiked,
    required VoidCallback onTap,
    double size = 24.0,
    Color likedColor = Colors.red,
    Color unlikedColor = Colors.grey,
    Duration duration = AnimationSystem.fast,
  }) {
    return _AnimatedLikeButton(
      isLiked: isLiked,
      onTap: onTap,
      size: size,
      likedColor: likedColor,
      unlikedColor: unlikedColor,
      duration: duration,
    );
  }

  /// Animated bookmark button
  static Widget animatedBookmarkButton({
    required bool isBookmarked,
    required VoidCallback onTap,
    double size = 24.0,
    Color bookmarkedColor = Colors.blue,
    Color unbookmarkedColor = Colors.grey,
    Duration duration = AnimationSystem.fast,
  }) {
    return _AnimatedBookmarkButton(
      isBookmarked: isBookmarked,
      onTap: onTap,
      size: size,
      bookmarkedColor: bookmarkedColor,
      unbookmarkedColor: unbookmarkedColor,
      duration: duration,
    );
  }

  /// Floating action button with bounce animation
  static Widget bouncingFAB({
    required VoidCallback onPressed,
    required Widget child,
    Color backgroundColor = Colors.blue,
    Color foregroundColor = Colors.white,
    double size = 56.0,
  }) {
    return _BouncingFAB(
      onPressed: onPressed,
      child: child,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      size: size,
    );
  }

  /// Swipe to dismiss with animation
  static Widget swipeToDismiss({
    required Widget child,
    required VoidCallback onDismissed,
    DismissDirection direction = DismissDirection.endToStart,
    Color backgroundColor = Colors.red,
    IconData icon = Icons.delete,
  }) {
    return _SwipeToDismissWidget(
      child: child,
      onDismissed: onDismissed,
      direction: direction,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  /// Pull to refresh with custom animation
  static Widget customPullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color color = Colors.blue,
    double displacement = 40.0,
  }) {
    return _CustomPullToRefresh(
      child: child,
      onRefresh: onRefresh,
      color: color,
      displacement: displacement,
    );
  }

  /// Animated counter with number changes
  static Widget animatedCounter({
    required int value,
    Duration duration = AnimationSystem.normal,
    TextStyle? textStyle,
    Color color = Colors.black,
  }) {
    return _AnimatedCounter(
      value: value,
      duration: duration,
      textStyle: textStyle,
      color: color,
    );
  }

  /// Ripple effect on tap
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color rippleColor = Colors.blue,
    double borderRadius = 8.0,
  }) {
    return _RippleEffectWidget(
      child: child,
      onTap: onTap,
      rippleColor: rippleColor,
      borderRadius: borderRadius,
    );
  }

  /// Animated toggle switch
  static Widget animatedToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.grey,
    Duration duration = AnimationSystem.fast,
  }) {
    return _AnimatedToggle(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      duration: duration,
    );
  }
}

/// Animated like button implementation
class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final Color likedColor;
  final Color unlikedColor;
  final Duration duration;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.onTap,
    required this.size,
    required this.likedColor,
    required this.unlikedColor,
    required this.duration,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;

    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = AnimationSystem.createScaleAnimation(
      _scaleController,
      begin: 1.0,
      end: 1.3,
      curve: Curves.elasticOut,
    );

    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
      _animateLike();
    }
  }

  void _animateLike() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    _heartController.forward();
    AnimationSystem.lightImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLiked = !_isLiked;
        });
        _animateLike();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _heartAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color: _isLiked ? widget.likedColor : widget.unlikedColor,
                ),
                if (_heartAnimation.value > 0)
                  Opacity(
                    opacity: _heartAnimation.value,
                    child: Icon(
                      Icons.favorite,
                      size: widget.size,
                      color: widget.likedColor,
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

/// Animated bookmark button implementation
class _AnimatedBookmarkButton extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback onTap;
  final double size;
  final Color bookmarkedColor;
  final Color unbookmarkedColor;
  final Duration duration;

  const _AnimatedBookmarkButton({
    required this.isBookmarked,
    required this.onTap,
    required this.size,
    required this.bookmarkedColor,
    required this.unbookmarkedColor,
    required this.duration,
  });

  @override
  State<_AnimatedBookmarkButton> createState() =>
      _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<_AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = AnimationSystem.createScaleAnimation(
      _controller,
      begin: 1.0,
      end: 1.2,
      curve: Curves.elasticOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_AnimatedBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBookmarked != widget.isBookmarked) {
      _isBookmarked = widget.isBookmarked;
      _animateBookmark();
    }
  }

  void _animateBookmark() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    AnimationSystem.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        _animateBookmark();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: widget.size,
                color: _isBookmarked
                    ? widget.bookmarkedColor
                    : widget.unbookmarkedColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bouncing FAB implementation
class _BouncingFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  const _BouncingFAB({
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.size,
  });

  @override
  State<_BouncingFAB> createState() => _BouncingFABState();
}

class _BouncingFABState extends State<_BouncingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    AnimationSystem.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: FloatingActionButton(
            onPressed: _handleTap,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Swipe to dismiss implementation
class _SwipeToDismissWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismissed;
  final DismissDirection direction;
  final Color backgroundColor;
  final IconData icon;

  const _SwipeToDismissWidget({
    required this.child,
    required this.onDismissed,
    required this.direction,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: direction,
      onDismissed: (_) => onDismissed(),
      background: Container(
        color: backgroundColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: child,
    );
  }
}

/// Custom pull to refresh implementation
class _CustomPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color color;
  final double displacement;

  const _CustomPullToRefresh({
    required this.child,
    required this.onRefresh,
    required this.color,
    required this.displacement,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color,
      displacement: displacement,
      child: child,
    );
  }
}

/// Animated counter implementation
class _AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;
  final Color color;

  const _AnimatedCounter({
    required this.value,
    required this.duration,
    this.textStyle,
    required this.color,
  });

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animateToValue(widget.value);
    }
  }

  void _animateToValue(int newValue) {
    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _currentValue = newValue;
      });
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
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animation.value * 0.1),
          child: Text(
            _currentValue.toString(),
            style: widget.textStyle ??
                TextStyle(
                  color: widget.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
    );
  }
}

/// Ripple effect implementation
class _RippleEffectWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color rippleColor;
  final double borderRadius;

  const _RippleEffectWidget({
    required this.child,
    required this.onTap,
    required this.rippleColor,
    required this.borderRadius,
  });

  @override
  State<_RippleEffectWidget> createState() => _RippleEffectWidgetState();
}

class _RippleEffectWidgetState extends State<_RippleEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    AnimationSystem.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              widget.child,
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      color: widget.rippleColor.withValues(
                        alpha: (1.0 - _rippleAnimation.value) * 0.3,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated toggle implementation
class _AnimatedToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Duration duration;

  const _AnimatedToggle({
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    required this.duration,
  });

  @override
  State<_AnimatedToggle> createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<_AnimatedToggle>
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
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
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
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
        AnimationSystem.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Color.lerp(
                widget.inactiveColor,
                widget.activeColor,
                _animation.value,
              ),
            ),
            child: Transform.translate(
              offset: Offset(_animation.value * 20, 0),
              child: Container(
                margin: const EdgeInsets.all(2),
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
