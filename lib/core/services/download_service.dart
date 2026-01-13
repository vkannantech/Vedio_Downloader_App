import '../models/video_model.dart';

abstract class IDownloadService {
  Future<void> initialize();
  Future<void> downloadVideo(String url);
  Future<void> cancelDownload(String id);
  Stream<List<VideoModel>> get activeDownloads;
  Stream<List<VideoModel>> get completedDownloads;
}

class DownloadService implements IDownloadService {
  @override
  Future<void> initialize() async {
    // TODO: Initialize native downloader
  }

  @override
  Stream<List<VideoModel>> get activeDownloads => Stream.value([]);

  @override
  Stream<List<VideoModel>> get completedDownloads => Stream.value([]);

  @override
  Future<void> cancelDownload(String id) async {
    // TODO: Implement cancel
  }

  @override
  Future<void> downloadVideo(String url) async {
    // TODO: Implement download
  }
}
