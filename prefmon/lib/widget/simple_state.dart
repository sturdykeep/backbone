import 'package:flutter/material.dart';

class SimpleState extends StatelessWidget {
  final String text;
  final IconData icon;
  const SimpleState({required this.text, required this.icon, Key? key})
      : super(key: key);
  const SimpleState.stopped({
    this.text = "Stopped",
    this.icon = Icons.report_rounded,
    super.key,
  });
  const SimpleState.starting(
      {this.text = "Starting",
      this.icon = Icons.run_circle_outlined,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Icon(
            icon,
            size: 50,
          )
        ],
      ),
    );
  }
}
