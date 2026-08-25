/// Application permissions — docs/10.15_Permission_Flows.md
enum AppPermission {
  notifications(
    title: 'Notifications',
    rationale:
        'Stay informed when downloads finish and control them from the notification shade.',
    optional: true,
  ),
  camera(
    title: 'Camera',
    rationale: 'Scan QR codes to start downloads faster.',
    optional: true,
  ),
  clipboard(
    title: 'Clipboard',
    rationale:
        'Detect copied download links and suggest quick actions. You can disable this anytime.',
    optional: true,
  );

  const AppPermission({
    required this.title,
    required this.rationale,
    required this.optional,
  });

  final String title;
  final String rationale;
  final bool optional;
}
