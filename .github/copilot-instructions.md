# Copilot instructions for `resque`

## Project shape
- This repo is a Flutter app scaffold, not a layered app yet. The entry point is `lib/main.dart`; app startup is `void main() => runApp(const MyApp())`.
- The primary domain model lives in `lib/models/sos_packet.dart`. It defines `SosPacket` and `EmergencyType`, with JSON serialization (`toJson` / `fromJson`) as the main data contract.
- There is no established service/repository layer yet; prefer adding features near the app’s existing minimal structure instead of introducing a large architecture before requirements are concrete.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) are standard Flutter-generated targets and should usually be left alone unless a platform-specific change is required.

## Domain and data conventions
- `EmergencyType` is an enum with fixed values: `medical`, `fire`, `flood`, `trapped`, `other`.
- `SosPacket` is the main payload object. Fields include `id`, `senderName`, `type`, `message`, `latitude`, `longitude`, `timestamp`, and `hopCount`.
- Serialization patterns are explicit: `timestamp` is stored as ISO 8601 string in JSON, and `EmergencyType.name` is used for the enum value.
- Keep model logic in Dart model classes; if a new packet or event type is added, mirror the same `toJson`/`fromJson` pattern used in `lib/models/sos_packet.dart`.

## Dependencies and integration points
- `geolocator` is the likely GPS/location dependency for SOS coordinates and alert creation.
- `connectivity_plus` indicates the app is expected to track connection state and possibly relay or queue emergency packets.
- `uuid` suggests IDs may be generated client-side for new packets.
- The project currently has no API client or backend layer; any networked behavior should be added in a focused way near the app logic rather than as a hidden global singleton.

## Workflow
- Install/update dependencies with `flutter pub get` or `flutter pub add <package>`.
- Validate the app with `flutter analyze` and `flutter test`.
- Run locally with `flutter run`.
- The repo uses default Flutter linting from `package:flutter_lints` and excludes generated build folders in `analysis_options.yaml`.

## Coding expectations
- Follow Flutter/Dart conventions used by the generated app: `StatelessWidget`/`StatefulWidget`, `MaterialApp`, `Scaffold`, and simple widget tree composition.
- Prefer small, explicit Dart classes over framework-heavy abstractions while the project is still minimal.
- When adding new files, keep them under `lib/` and name them from their responsibility (for example, `models/`, `services/`, `screens/` if the app expands).
- Avoid large refactors unless there is a demonstrated feature need; the codebase is still in early scaffold stage.

## Current reality
- This is a starter Flutter app with a concrete SOS packet model and dependency setup for mobile/location/network features, but it does not yet have a mature app architecture.
- AI agents should treat the codebase as a lightweight emergency/SOS prototype and make the smallest change consistent with the existing simple structure.
