import 'package:isar/isar.dart';

part 'download_item.g.dart';

@collection
class DownloadItem {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String url;

  late String title;
  
  String? thumbnailUrl;
  
  String? duration;
  
  String? uploader;

  @Enumerated(EnumType.ordinal)
  DownloadStatus status = DownloadStatus.queued;

  double progress = 0.0;

  int? totalBytes;       // Nullable if unknown
  int? downloadedBytes;
  
  String? speed; // e.g. "3.5 MB/s"
  String? eta;   // e.g. "00:45"

  late String downloadPath;

  @Index()
  late DateTime createdAt;

  DateTime? completedAt;

  // Configuration for yt-dlp
  String? formatId;
  bool isAudioOnly = false;
  bool isPlaylist = false;
  
  /// Helper to check if file is actionable (can pause/resume)
  bool get isActionable => status == DownloadStatus.downloading || status == DownloadStatus.queued;
}

enum DownloadStatus {
  queued,
  starting,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}
