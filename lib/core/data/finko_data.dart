// Firestore data model types and path helpers — see docs/data-model.md.
//
// JSON serialization uses `json_serializable` (generated `*.g.dart` files).
// After editing `@JsonSerializable` models, run:
//   dart run build_runner build --delete-conflicting-outputs
export 'firestore_map_utils.dart';
export 'firestore_paths.dart';
export 'json/json_converters.dart';
export 'models/models.dart';
