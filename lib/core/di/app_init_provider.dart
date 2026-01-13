import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../features/downloads/data/sources/native_downloader.dart';
import 'database_provider.dart';
import 'logic_provider.dart';

final appInitProvider = FutureProvider<Isar>((ref) async {
  // 1. Initialize Isar
  final isar = await ref.watch(isarProvider.future);
  
  // 2. Initialize Native Downloader (Extract binaries)
  final native = ref.read(nativeDownloaderProvider);
  final initResult = await native.initialize();
  
  initResult.fold(
    (l) => throw Exception("Native Init Failed: $l"), 
    (r) => null
  );

  // 3. Initialize Queue Engine (Logic)
  ref.read(queueEngineProvider);
  
  return isar;
});
