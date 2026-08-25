import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permissions/permissions.dart';
import 'package:shared_types/shared_types.dart';

/// Five-step onboarding — docs/10.1_Onboarding.md
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.storagePath,
    required this.onInitialize,
    required this.onComplete,
    this.onRequestPermission,
    this.onOpenSettings,
  });

  final String storagePath;
  final Future<void> Function() onInitialize;
  final Future<void> Function() onComplete;
  final Future<PermissionResult> Function(AppPermission permission)?
      onRequestPermission;
  final Future<void> Function()? onOpenSettings;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _stepCount = 5;
  var _step = 0;
  var _isLoading = false;
  final _permissionGranted = <AppPermission, bool>{};
  final _permissionDenied = <AppPermission, bool>{};

  double get _progress => (_step + 1) / _stepCount;

  Future<void> _next() async {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    try {
      await widget.onInitialize();
      await widget.onComplete();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $error')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestPermission(AppPermission permission) async {
    final request = widget.onRequestPermission;
    if (request == null) return;
    final result = await request(permission);
    setState(() {
      _permissionGranted[permission] = result.granted;
      _permissionDenied[permission] = result.permanentlyDenied;
    });
    if (result.permanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${permission.title} blocked. Enable it in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => widget.onOpenSettings?.call(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      0 => _welcome(),
      1 => _features(),
      2 => _permissions(),
      3 => _storage(),
      _ => _ready(),
    };
  }

  Widget _welcome() {
    return OnboardingLayout(
      progress: _progress,
      icon: Icons.download_for_offline_outlined,
      title: 'Welcome to ${AppIdentity.displayName}',
      body: Text(
        'Download, organize, and manage files with a fast, modern experience.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      primaryActionLabel: 'Get started',
      onPrimaryAction: _next,
    );
  }

  Widget _features() {
    return OnboardingLayout(
      progress: _progress,
      title: 'Everything you need',
      body: const Column(
        children: [
          FeatureHighlight(
            icon: Icons.speed,
            title: 'Fast downloads',
            subtitle: 'Queue, pause, resume, and retry with ease.',
          ),
          FeatureHighlight(
            icon: Icons.content_paste,
            title: 'Clipboard detection',
            subtitle: 'Smart suggestions when you copy download links.',
          ),
          FeatureHighlight(
            icon: Icons.language,
            title: 'Built-in browser',
            subtitle: 'Browse and download from the web in one place.',
          ),
          FeatureHighlight(
            icon: Icons.folder_copy,
            title: 'Smart organization',
            subtitle: 'Files sorted automatically by type.',
          ),
        ],
      ),
      primaryActionLabel: 'Continue',
      onPrimaryAction: _next,
      secondaryActionLabel: 'Back',
      onSecondaryAction: _back,
    );
  }

  Widget _permissions() {
    if (kIsWeb) {
      return OnboardingLayout(
        progress: _progress,
        title: 'Browser limits',
        body: Text(
          'Downloads run while this tab is open. Social and site URLs use a local proxy so they work like on Android. Start it with `dart run tool/cors_proxy.dart` from apps/web before launching Chrome.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        primaryActionLabel: 'Continue',
        onPrimaryAction: _next,
        secondaryActionLabel: 'Back',
        onSecondaryAction: _back,
      );
    }
    return OnboardingLayout(
      progress: _progress,
      title: 'Permissions',
      body: ListView(
        children: [
          Text(
            'We only ask for what helps the app work better. You can change these later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: UdmSpacing.lg),
          PermissionCard(
            title: AppPermission.notifications.title,
            description: AppPermission.notifications.rationale,
            optional: true,
            granted: _permissionGranted[AppPermission.notifications],
            actionLabel: _permissionDenied[AppPermission.notifications] == true
                ? 'Open Settings'
                : 'Allow',
            onRequest: _permissionDenied[AppPermission.notifications] == true
                ? widget.onOpenSettings
                : () => _requestPermission(AppPermission.notifications),
          ),
          const SizedBox(height: UdmSpacing.md),
          PermissionCard(
            title: AppPermission.camera.title,
            description: AppPermission.camera.rationale,
            optional: true,
            granted: _permissionGranted[AppPermission.camera],
            actionLabel: _permissionDenied[AppPermission.camera] == true
                ? 'Open Settings'
                : 'Allow',
            onRequest: _permissionDenied[AppPermission.camera] == true
                ? widget.onOpenSettings
                : () => _requestPermission(AppPermission.camera),
          ),
          const SizedBox(height: UdmSpacing.md),
          PermissionCard(
            title: AppPermission.clipboard.title,
            description: AppPermission.clipboard.rationale,
            optional: true,
            granted: _permissionGranted[AppPermission.clipboard] ?? true,
          ),
        ],
      ),
      primaryActionLabel: 'Continue',
      onPrimaryAction: _next,
      secondaryActionLabel: 'Back',
      onSecondaryAction: _back,
    );
  }

  Widget _storage() {
    return OnboardingLayout(
      progress: _progress,
      title: 'Storage setup',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kIsWeb
                ? 'Files are stored in this browser. Use Save / Open in Files to download them to your computer.'
                : 'Downloads are saved in a dedicated app folder. You can change the location later in Settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: UdmSpacing.xxl),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(kIsWeb ? 'Browser storage' : 'Default location'),
              subtitle: Text(
                widget.storagePath,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      primaryActionLabel: 'Continue',
      onPrimaryAction: _next,
      secondaryActionLabel: 'Back',
      onSecondaryAction: _back,
    );
  }

  Widget _ready() {
    return OnboardingLayout(
      progress: _progress,
      icon: Icons.check_circle_outline,
      title: "You're all set",
      body: Text(
        'Your library and download queue are ready. Start downloading whenever you like.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      primaryActionLabel: 'Start downloading',
      onPrimaryAction: _isLoading ? null : _finish,
      secondaryActionLabel: 'Back',
      onSecondaryAction: _isLoading ? null : _back,
      isLoading: _isLoading,
    );
  }
}
