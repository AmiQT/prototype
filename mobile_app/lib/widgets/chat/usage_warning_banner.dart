import 'package:flutter/material.dart';

class UsageWarningBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const UsageWarningBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Approaching daily usage limits. Chat may be limited.',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.orange[700],
              size: 18,
            ),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
}
