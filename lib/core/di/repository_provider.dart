import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/downloads/data/repositories/isar_download_repository.dart';
import '../../features/downloads/domain/repositories/i_download_repository.dart';
import 'database_provider.dart';

final downloadRepositoryProvider = Provider<IDownloadRepository>((ref) {
  final isar = ref.watch(isarProvider).valueOrNull;
  if (isar == null) throw UnimplementedError('Database not initialized');
  return IsarDownloadRepository(isar);
});
