# Dependency audit

No major upgrades were performed as part of open-source preparation. All application packages use `publish_to: none`. Sources are **pub.dev** plus path dependencies.

Caret ranges (`^`) are normal for Flutter; they are not the same as `"*"`. No `*` version was found in workspace pubspecs.

Flutter SDK pins differ by package (see table). Treat **Flutter 3.44+** as the app requirement.

## Workspace / SDK

| Dependency | Current version | Concern | Recommendation |
| ---------- | --------------- | ------- | -------------- |
| Dart SDK | `^3.10.0` | Consistent | Keep |
| Flutter (`apps/mobile`, `job_manager`) | `>=3.44.0` | Newer than other packages (`>=3.24.0` / `>=3.38.0`) | Document 3.44+; optionally unify later |
| Melos | `^8.2.2` | Workspace only | Keep |
| `flutter_lints` | `^6.0.0` | Dev | Keep |

## Runtime (pub.dev)

| Dependency | Current version | Concern | Recommendation |
| ---------- | --------------- | ------- | -------------- |
| flutter_riverpod | `^2.6.1` | Core state | Keep; do not add Bloc/GetX |
| go_router | `^16.2.0` | Major 16 | Keep |
| dio | `^5.9.0` | Engine HTTP | Keep |
| uuid | `^4.5.1` | | Keep |
| path | `^1.9.1` | | Keep |
| sqflite | `^2.4.2` | As-built DB | Do not replace with Drift |
| sqflite_common_ffi_web | `^1.0.4` | Web | Keep; wasm file is tracked |
| path_provider | `^2.1.5` | | Keep |
| shared_preferences | `^2.5.5` (mobile) / `^2.5.3` (packages) | Slight mismatch | Harmless; unify when convenient |
| flutter_foreground_task | `^11.0.1` | Android FG | Keep |
| flutter_local_notifications | `^19.0.0` | | Keep |
| connectivity_plus | `^6.1.4` | | Keep |
| permission_handler | `^12.0.1` | | Keep |
| webview_flutter | `^4.14.0` | | Keep |
| webview_flutter_web | `^0.2.3+4` | | Keep |
| receive_sharing_intent | `^1.9.0` | Android share | Keep |
| mobile_scanner | `^7.0.1` | Camera | Keep |
| video_player | `^2.14.0` | | Keep |
| open_filex | `^4.7.0` | | Keep |
| share_plus | `^13.2.1` | | Keep |
| gal | `^2.3.3` | Save to gallery | Keep |
| mime | `^2.0.0` | | Keep |
| web | `^1.1.1` | storage web | Keep |
| cupertino_icons | `^1.0.8` | | Keep |
| firebase_core | `^4.14.0` | Optional until `google-services.json` | Keep; no-op without config |
| firebase_crashlytics | `^5.3.0` | Same | Keep |
| firebase_performance | `^0.11.5` | 0.x API | Watch for breaking 1.x |
| firebase_remote_config | `^6.6.0` | | Keep |
| posthog_flutter | `^5.3.1` | Needs dart-define key | Keep |
| device_info_plus | `^13.0.0` | | Keep |
| package_info_plus | `^10.0.0` | | Keep |

## Overrides (mobile app)

| Dependency | Current version | Concern | Recommendation |
| ---------- | --------------- | ------- | -------------- |
| shared_preferences_android | `2.4.27` (exact) | Pins around Kotlin Gradle Plugin | Keep until AGP/Flutter catch up |
| webview_flutter_android | `4.14.0` (exact) | Same | Keep |

## Dev / test

| Dependency | Current version | Concern | Recommendation |
| ---------- | --------------- | ------- | -------------- |
| sqflite_common_ffi | `^2.3.6` | Tests | Keep |
| path_provider_platform_interface | `^2.1.2` | Test fakes | Keep |
| plugin_platform_interface | `^2.1.8` | Test fakes | Keep |
| udm_qa_server | path `qa/server` | Local fixture server | Keep unpublished |

## License compatibility

Typical Flutter plugins are BSD-3-Clause, MIT, or Apache-2.0. Those licenses are **compatible with MIT** for this application's own code. Do not add GPL-only dependencies without a governance discussion.

Firebase / Play Services binaries have Google terms; they are optional at runtime.

## Private / risky

| Item | Concern | Recommendation |
| ---- | ------- | -------------- |
| Private registries | None found | — |
| Wildcard `*` | None found | — |
| Unpinned git deps | None found | — |
| `analytics` Firebase | Needs a local `google-services.json` | Gitignore the live file |
| Social resolvers | Depend on third-party HTML/APIs that can break | Tests + fail closed; not a pub dependency risk |

## Lockfiles

`downivo/.gitignore` ignores most `pubspec.lock` files but keeps `apps/mobile/pubspec.lock`. Package-level locks are therefore not the reproducibility source for libraries — the app lock is.

**Do not** run a wide `flutter pub upgrade` as part of going public.
