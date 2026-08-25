import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Start page shown for `udm://home` tabs.
class BrowserHome extends StatelessWidget {
  const BrowserHome({
    super.key,
    required this.onQuickLink,
    required this.onSearch,
  });

  final ValueChanged<String> onQuickLink;
  final ValueChanged<String> onSearch;

  static const quickLinks = [
    ('Google', 'https://www.google.com'),
    ('GitHub', 'https://github.com'),
    ('Archive.org', 'https://archive.org'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(UdmSpacing.lg),
      children: [
        const UdmSectionLabel(label: 'Browser'),
        Text(
          'Enter a URL or search the web. Downloadable links are detected automatically.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: UdmSpacing.xl),
        _QuickSearchField(onSubmitted: onSearch),
        const SizedBox(height: UdmSpacing.xl),
        const UdmSectionLabel(label: 'Quick links'),
        ...quickLinks.map(
          (entry) => Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: Text(entry.$1),
              subtitle: Text(entry.$2),
              onTap: () => onQuickLink(entry.$2),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickSearchField extends StatefulWidget {
  const _QuickSearchField({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_QuickSearchField> createState() => _QuickSearchFieldState();
}

class _QuickSearchFieldState extends State<_QuickSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search or enter URL',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => widget.onSubmitted(_controller.text),
        ),
      ),
      textInputAction: TextInputAction.go,
      onSubmitted: widget.onSubmitted,
    );
  }
}
