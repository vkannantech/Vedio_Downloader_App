import 'package:fpdart/fpdart.dart';
import 'package:isar/isar.dart';
import '../../data/models/download_item.dart';
import '../../domain/repositories/i_download_repository.dart';

class IsarDownloadRepository implements IDownloadRepository {
  final Isar isar;

  IsarDownloadRepository(this.isar);

  @override
  Future<Either<String, int>> addDownload(DownloadItem item) async {
    try {
      final id = await isar.writeTxn(() async {
        return await isar.downloadItems.put(item);
      });
      return Right(id);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<List<DownloadItem>> getAllDownloads() async {
    return await isar.downloadItems.where().findAll();
  }

  @override
  Stream<List<DownloadItem>> watchAllDownloads() {
    return isar.downloadItems.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  @override
  Stream<List<DownloadItem>> watchActiveDownloads() {
    return isar.downloadItems
        .filter()
        .statusEqualTo(DownloadStatus.downloading)
        .or()
        .statusEqualTo(DownloadStatus.queued)
        .or()
        .statusEqualTo(DownloadStatus.starting)
        .watch(fireImmediately: true);
  }

  @override
  Future<Either<String, void>> cancelDownload(int id) async {
    try {
      await isar.writeTxn(() async {
        final item = await isar.downloadItems.get(id);
        if (item != null) {
          item.status = DownloadStatus.canceled;
          await isar.downloadItems.put(item);
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteDownload(int id, {bool deleteFile = false}) async {
    try {
      await isar.writeTxn(() async {
        await isar.downloadItems.delete(id);
      });
      if (deleteFile) {
        // TODO: Implement file deletion
      }
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> pauseDownload(int id) async {
    return _updateStatus(id, DownloadStatus.paused);
  }

  @override
  Future<Either<String, void>> resumeDownload(int id) async {
    return _updateStatus(id, DownloadStatus.queued);
  }

  Future<Either<String, void>> _updateStatus(int id, DownloadStatus status) async {
    try {
      await isar.writeTxn(() async {
        final item = await isar.downloadItems.get(id);
        if (item != null) {
          item.status = status;
          await isar.downloadItems.put(item);
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<void> updateProgress(int id, double progress, int downloadedBytes) async {
    await isar.writeTxn(() async {
      final item = await isar.downloadItems.get(id);
      if (item != null) {
        item.progress = progress;
        item.downloadedBytes = downloadedBytes;
        // Don't change status to completed here, let the engine handle it
        await isar.downloadItems.put(item);
      }
    });
  }

  @override
  Future<void> updateStatus(int id, DownloadStatus status) async {
    await isar.writeTxn(() async {
      final item = await isar.downloadItems.get(id);
      if (item != null) {
        item.status = status;
        if (status == DownloadStatus.completed) {
          item.completedAt = DateTime.now();
          item.progress = 1.0;
        }
        await isar.downloadItems.put(item);
      }
    });
  }

  @override
  Future<void> updateStats(int id, String? speed, String? eta) async {
    await isar.writeTxn(() async {
      final item = await isar.downloadItems.get(id);
      if (item != null) {
        item.speed = speed;
        item.eta = eta;
        await isar.downloadItems.put(item);
      }
    });
  }
}
