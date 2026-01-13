import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/download_item.dart';
import '../../domain/repositories/i_download_repository.dart';
import '../../data/sources/native_downloader.dart';

final queueEngineProvider = Provider<QueueEngine>((ref) {
  // In a real app we would get repository from ref
  // But for this step I am assuming the repository provider is available
  // Let's defer dependency injection to the main provider definition file.
  throw UnimplementedError("Use the main DI file");
});

class QueueEngine {
  final IDownloadRepository _repository;
  final NativeDownloader _nativeDownloader;

  // Configuration
  static const int kMaxConcurrentDownloads = 3;

  QueueEngine(this._repository, this._nativeDownloader) {
    _init();
  }

  void _init() {
    // 1. Watch for changes in the queue and react
    _repository.watchActiveDownloads().listen((activeItems) {
      _processQueue(activeItems);
    });

    // 2. Listen to native progress events
    _nativeDownloader.progressStream.listen((event) {
      if (event is Map) {
        final idStr = event['id'] as String?;
        final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;
        final statusStr = event['status'] as String?;
        final line = event['line'] as String?;
        
        if (idStr != null) {
          final id = int.tryParse(idStr);
          if (id != null) {
            _handleProgressUpdate(id, progress, statusStr, line);
          }
        }
      }
    });
  }

  void _handleProgressUpdate(int id, double progress, String? statusStr, String? line) {
    DownloadStatus status = DownloadStatus.downloading;
    if (statusStr == 'completed') status = DownloadStatus.completed;
    else if (statusStr == 'failed') status = DownloadStatus.failed;
    else if (statusStr == 'canceled') status = DownloadStatus.canceled;

    // TODO: For "Ultra-Pro" smoothness, we should debounce DB writes or use an in-memory state.
    // For now, to ensure persistence, we write to Isar.
    // Isar is extremely fast, so this is acceptable for < 5 concurrent downloads.
    
    // We don't have bytes info from this specific event channel map yet, so passing 0
    // Parse the raw line for stats
    String? speed;
    String? eta;
    
    // Example line: [download]  45.0% of 10.00MiB at  2.50MiB/s ETA 00:05
    if (line != null && line.isNotEmpty) {
      if (line.contains("at ") && line.contains("ETA ")) {
        try {
           final parts = line.split(" ");
           // This is a naive split, regex is safer but let's try a simple extraction first or regex
           final speedRegex = RegExp(r"at\s+([0-9.]+\w+/s)");
           final etaRegex = RegExp(r"ETA\s+([0-9:]+)");
           
           final speedMatch = speedRegex.firstMatch(line);
           if (speedMatch != null) speed = speedMatch.group(1);
           
           final etaMatch = etaRegex.firstMatch(line);
           if (etaMatch != null) eta = etaMatch.group(1);
        } catch (e) {
           // ignore parse errors
        }
      }
    }

    _repository.updateProgress(id, progress, 0); 
    _repository.updateStatus(id, status);
    if (speed != null || eta != null) {
       _repository.updateStats(id, speed, eta);
    }
  }

  Future<void> _processQueue(List<DownloadItem> activeItems) async {
    final downloadingCount = activeItems.where((i) => i.status == DownloadStatus.downloading).length;
    
    if (downloadingCount < kMaxConcurrentDownloads) {
      // Find next queued item
      final queuedItems = activeItems.where((i) => i.status == DownloadStatus.queued).toList();
      queuedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // FIFO

      for (var item in queuedItems) {
        if (downloadingCount >= kMaxConcurrentDownloads) break;
        
        // Start this download
        _startDownload(item);
      }
    }
  }

  Future<void> _startDownload(DownloadItem item) async {
    // 1. Update status to starting
    await _repository.updateStatus(item.id, DownloadStatus.starting);

    // 2. Call Native Bridge
    final result = await _nativeDownloader.startDownload(
      id: item.id.toString(),
      url: item.url,
      savePath: item.downloadPath,
      isAudioOnly: item.isAudioOnly,
      formatId: item.formatId,
    );

    result.fold(
      (error) {
        // Failed to start
        _repository.updateStatus(item.id, DownloadStatus.failed);
      },
      (success) {
        // Started successfully
        _repository.updateStatus(item.id, DownloadStatus.downloading);
      },
    );
  }
}
