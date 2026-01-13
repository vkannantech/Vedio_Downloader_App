import 'package:fpdart/fpdart.dart';
import '../../data/models/download_item.dart';

abstract class IDownloadRepository {
  // Queries
  Future<List<DownloadItem>> getAllDownloads();
  Stream<List<DownloadItem>> watchAllDownloads();
  Stream<List<DownloadItem>> watchActiveDownloads();
  
  // Actions
  Future<Either<String, int>> addDownload(DownloadItem item);
  Future<Either<String, void>> pauseDownload(int id);
  Future<Either<String, void>> resumeDownload(int id);
  Future<Either<String, void>> cancelDownload(int id);
  Future<Either<String, void>> deleteDownload(int id, {bool deleteFile = false});
  
  // Internal
  Future<void> updateProgress(int id, double progress, int downloadedBytes);
  Future<void> updateStatus(int id, DownloadStatus status);
  Future<void> updateStats(int id, String? speed, String? eta);
}
