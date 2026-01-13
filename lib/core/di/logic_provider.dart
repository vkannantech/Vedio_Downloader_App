import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/downloads/data/sources/native_downloader.dart';
import '../../features/downloads/domain/logic/queue_engine.dart';
import 'repository_provider.dart';

final nativeDownloaderProvider = Provider<NativeDownloader>((ref) => NativeDownloader());

final queueEngineProvider = Provider<QueueEngine>((ref) {
  final repository = ref.watch(downloadRepositoryProvider);
  final nativeDownloader = ref.watch(nativeDownloaderProvider);
  return QueueEngine(repository, nativeDownloader);
});
