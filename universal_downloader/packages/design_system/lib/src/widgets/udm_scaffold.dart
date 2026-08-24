import 'package:flutter/material.dart';

class UdmScaffold extends StatelessWidget {
  const UdmScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(title),
        ),
        actions: actions,
      ),
      body: Semantics(
        container: true,
        label: '$title screen',
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
