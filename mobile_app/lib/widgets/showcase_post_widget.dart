import 'package:flutter/material.dart';

class ShowcasePostWidget extends StatelessWidget {
  final String title;
  final String description;
  final bool isImage;

  const ShowcasePostWidget({
    super.key,
    required this.title,
    required this.description,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description),
            if (isImage)
              Container(
                height: 100,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Text('Image Placeholder'),
              ),
          ],
        ),
      ),
    );
  }
}
