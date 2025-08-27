import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';

class ThemeToggleButton extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String? lightLabel;
  final String? darkLabel;
  final String? systemLabel;

  const ThemeToggleButton({
    super.key,
    this.size = 48.0,
    this.showLabel = false,
    this.lightLabel,
    this.darkLabel,
    this.systemLabel,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleThemeToggle() async {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final themeProvider = context.read<ThemeProvider>();
    await themeProvider.toggleTheme();
  }

  IconData _getThemeIcon(ThemeProvider themeProvider) {
    if (themeProvider.isSystemTheme) {
      return Icons.brightness_auto;
    } else if (themeProvider.isDarkMode) {
      return Icons.dark_mode;
    } else {
      return Icons.light_mode;
    }
  }

  Color _getThemeColor(ThemeProvider themeProvider) {
    if (themeProvider.isSystemTheme) {
      return AppTheme.infoColor;
    } else if (themeProvider.isDarkMode) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.secondaryColor;
    }
  }

  String _getThemeLabel(ThemeProvider themeProvider) {
    if (themeProvider.isSystemTheme) {
      return widget.systemLabel ?? 'System';
    } else if (themeProvider.isDarkMode) {
      return widget.darkLabel ?? 'Dark';
    } else {
      return widget.lightLabel ?? 'Light';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _handleThemeToggle,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          color: _getThemeColor(themeProvider)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(widget.size / 2),
                          border: Border.all(
                            color: _getThemeColor(themeProvider)
                                .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getThemeIcon(themeProvider),
                          color: _getThemeColor(themeProvider),
                          size: widget.size * 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              Text(
                _getThemeLabel(themeProvider),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
