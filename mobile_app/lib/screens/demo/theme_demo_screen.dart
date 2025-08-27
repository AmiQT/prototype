import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/modern/modern_button.dart';
import '../../widgets/modern/modern_text_field.dart';
import '../../utils/app_theme.dart';

class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _switchValue = false;
  bool _checkboxValue = false;
  int _radioValue = 1;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dark Mode Demo'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: AppTheme.spaceMd),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Text(
                          'Current Theme',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode: ${themeProvider.currentThemeString}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              'Brightness: ${Theme.of(context).brightness.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // Typography Demo
            Text(
              'Typography',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Large',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      'Headline Medium',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Title Large',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Body Large - This is the main body text that users will read most often.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Body Medium - Secondary text content.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Body Small - Caption and helper text.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // Buttons Demo
            Text(
              'Buttons',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ModernButton(
                      text: 'Primary Button',
                      type: ModernButtonType.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const ModernButton(
                      text: 'Secondary Button',
                      type: ModernButtonType.secondary,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const ModernButton(
                      text: 'Outline Button',
                      type: ModernButtonType.outline,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Elevated'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Outlined'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Text'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // Form Elements Demo
            Text(
              'Form Elements',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  children: [
                    ModernTextField(
                      controller: _textController,
                      label: 'Text Field',
                      hintText: 'Enter some text...',
                      icon: Icons.text_fields,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    SwitchListTile(
                      title: const Text('Switch'),
                      subtitle: const Text('Toggle this switch'),
                      value: _switchValue,
                      onChanged: (value) {
                        setState(() {
                          _switchValue = value;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Checkbox'),
                      subtitle: const Text('Check this option'),
                      value: _checkboxValue,
                      onChanged: (value) {
                        setState(() {
                          _checkboxValue = value ?? false;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Radio Option 1'),
                      value: 1,
                      groupValue: _radioValue,
                      onChanged: (value) {
                        setState(() {
                          _radioValue = value ?? 1;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Radio Option 2'),
                      value: 2,
                      groupValue: _radioValue,
                      onChanged: (value) {
                        setState(() {
                          _radioValue = value ?? 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // Colors Demo
            Text(
              'Color Palette',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  children: [
                    _buildColorRow(
                      context,
                      'Primary',
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                    _buildColorRow(
                      context,
                      'Secondary',
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.onSecondary,
                    ),
                    _buildColorRow(
                      context,
                      'Surface',
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                    _buildColorRow(
                      context,
                      'Error',
                      Theme.of(context).colorScheme.error,
                      Theme.of(context).colorScheme.onError,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space2xl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Floating Action Button pressed!'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildColorRow(
      BuildContext context, String name, Color color, Color onColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.palette,
              color: onColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
