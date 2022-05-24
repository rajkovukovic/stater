import 'package:flutter/material.dart';

class TutorialCard extends StatelessWidget {
  const TutorialCard({
    Key? key,
    required this.tutorial,
    this.onTap,
  }) : super(key: key);

  final Map<String, dynamic> tutorial;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final published = tutorial['published'] == true;
    return Card(
      color: Colors.lightBlue.shade100,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                tutorial['title'],
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              SelectableText(tutorial['description']),
              const SizedBox(height: 8),
              SelectableText(
                published ? 'published' : 'not published',
                style: TextStyle(color: published ? Colors.blueAccent : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
