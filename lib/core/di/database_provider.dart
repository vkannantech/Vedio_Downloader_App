import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/downloads/data/models/download_item.dart';

// Access Isar instance anywhere
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [DownloadItemSchema],
    directory: dir.path,
    inspector: true, // Allow inspecting DB in debug builds
  );
});
