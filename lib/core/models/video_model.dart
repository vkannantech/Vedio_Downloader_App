class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String duration;
  final String uploader;
  final double progress;
  final bool isDownloaded;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
    required this.uploader,
    this.progress = 0.0,
    this.isDownloaded = false,
  });

  factory VideoModel.mock() {
    return VideoModel(
      id: '1',
      title: 'Clivon Introduction',
      thumbnailUrl: 'https://placeholder.com/300x200',
      duration: '10:00',
      uploader: 'KannanTech',
      progress: 0.5,
    );
  }
}
