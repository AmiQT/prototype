import 'package:flutter/material.dart';
import 'animation_system.dart';

/// Custom page transitions for smooth navigation
class PageTransitions {
  /// Slide from right transition
  static Route<T> slideFromRight<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.slideIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Slide from bottom transition
  static Route<T> slideFromBottom<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.slideIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Fade transition
  static Route<T> fade<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: curve),
          ),
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static Route<T> scale<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.bounceIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            CurveTween(curve: curve),
          ),
          child: child,
        );
      },
    );
  }

  /// Combined slide and fade transition
  static Route<T> slideAndFade<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Offset slideBegin = const Offset(0.0, 0.3),
    Offset slideEnd = Offset.zero,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween(begin: slideBegin, end: slideEnd);
        final fadeTween = Tween(begin: 0.0, end: 1.0);
        final curveTween = CurveTween(curve: curve);

        return SlideTransition(
          position: animation.drive(slideTween.chain(curveTween)),
          child: FadeTransition(
            opacity: animation.drive(fadeTween.chain(curveTween)),
            child: child,
          ),
        );
      },
    );
  }

  /// Hero transition for shared elements
  static Route<T> hero<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.smoothIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: curve),
          ),
          child: child,
        );
      },
    );
  }

  /// Modal bottom sheet transition
  static Route<T> modalBottomSheet<T extends Object?>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AnimationSystem.normal,
    Curve curve = AnimationSystem.slideIn,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// Navigation helper with smooth transitions
class SmoothNavigator {
  /// Push with slide from right
  static Future<T?> pushSlideFromRight<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.slideFromRight<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Push with slide from bottom
  static Future<T?> pushSlideFromBottom<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.slideFromBottom<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Push with fade
  static Future<T?> pushFade<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.fade<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Push with scale
  static Future<T?> pushScale<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.scale<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Push with slide and fade
  static Future<T?> pushSlideAndFade<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.slideAndFade<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Push modal bottom sheet
  static Future<T?> pushModalBottomSheet<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
  }) {
    return Navigator.push<T>(
      context,
      PageTransitions.modalBottomSheet<T>(
        page: page,
        settings: settings,
      ),
    );
  }

  /// Replace with slide from right
  static Future<T?>
      pushReplacementSlideFromRight<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    TO? result,
  }) {
    return Navigator.pushReplacement<T, TO>(
      context,
      PageTransitions.slideFromRight<T>(
        page: page,
        settings: settings,
      ),
      result: result,
    );
  }

  /// Push and remove until
  static Future<T?> pushAndRemoveUntilSlideFromRight<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    RouteSettings? settings,
  }) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      PageTransitions.slideFromRight<T>(
        page: page,
        settings: settings,
      ),
      predicate,
    );
  }
}
