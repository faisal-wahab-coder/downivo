import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UdmScaffold(
      title: 'Home',
      body: const EmptyState(
        icon: Icons.dashboard_outlined,
        title: 'Welcome to Universal Downloader',
        subtitle:
            'Active downloads, recent files, and storage summary will appear here.',
      ),
    );
  }
}

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UdmScaffold(
      title: 'Browser',
      body: const EmptyState(
        icon: Icons.language_outlined,
        title: 'Built-in browser',
        subtitle: 'Browse the web and download files directly from pages.',
      ),
    );
  }
}

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UdmScaffold(
      title: 'Files',
      body: const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No files yet',
        subtitle:
            'Downloaded files will be organized by category in this library.',
      ),
    );
  }
}
