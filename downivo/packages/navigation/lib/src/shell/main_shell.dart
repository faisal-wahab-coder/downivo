import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:design_system/design_system.dart';
import 'package:shared_types/shared_types.dart';

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _destinations = <_ShellDestination>[
    _ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    _ShellDestination(
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
      label: 'Downloads',
    ),
    _ShellDestination(
      icon: Icons.language_outlined,
      selectedIcon: Icons.language,
      label: 'Browser',
    ),
    _ShellDestination(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: 'Files',
    ),
    _ShellDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop;
    final scaffold = wide
        ? Scaffold(
            body: Row(
              children: [
                _DesktopRail(
                  currentIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: _destinations,
                ),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: child),
              ],
            ),
          )
        : Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final dest in _destinations)
                  NavigationDestination(
                    icon: Icon(dest.icon),
                    selectedIcon: Icon(dest.selectedIcon),
                    label: dest.label,
                  ),
              ],
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleRootBack(context);
      },
      child: scaffold,
    );
  }

  Future<void> _handleRootBack(BuildContext context) async {
    // Nested screens (history, search, file detail) live on a branch
    // Navigator and receive system back first. Do not use GoRouter.canPop()
    // here — it is true at /home whenever the shell itself is poppable, which
    // skipped the dialog and exited the app.
    if (currentIndex != 0) {
      onDestinationSelected(0);
      return;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit ${AppIdentity.displayName}?'),
        content: const Text(
          'Downloads in progress will stop if you leave the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true && context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

class _DesktopRail extends StatelessWidget {
  const _DesktopRail({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = destinations.take(destinations.length - 1);
    final settings = destinations.last;

    return ColoredBox(
      color: scheme.surface,
      child: SizedBox(
        width: 80,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: UdmSpacing.lg),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: UdmColors.signalCyan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  AppIdentity.railMark,
                  style: TextStyle(
                    color: UdmColors.onAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'V1.0',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: UdmSpacing.xl),
              for (var i = 0; i < primary.length; i++)
                _RailItem(
                  destination: destinations[i],
                  selected: currentIndex == i,
                  onTap: () => onDestinationSelected(i),
                ),
              const Spacer(),
              _RailItem(
                destination: settings,
                selected: currentIndex == destinations.length - 1,
                onTap: () => onDestinationSelected(destinations.length - 1),
              ),
              const SizedBox(height: UdmSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? UdmColors.signalCyan
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 80,
          height: 64,
          child: Stack(
            children: [
              if (selected)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                      color: UdmColors.signalCyan,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
