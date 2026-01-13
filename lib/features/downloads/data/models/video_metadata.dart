
import 'dart:convert';

class VideoMetadata {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final String? uploader;
  final int? duration;
  final List<VideoFormat> formats;

  VideoMetadata({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    this.uploader,
    this.duration,
    required this.formats,
  });

  factory VideoMetadata.fromJson(String jsonStr) {
    final Map<String, dynamic> map = json.decode(jsonStr);
    return VideoMetadata.fromMap(map);
  }

  factory VideoMetadata.fromMap(Map<String, dynamic> map) {
    return VideoMetadata(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      description: map['description'],
      thumbnail: map['thumbnail'],
      uploader: map['uploader'],
      duration: map['duration'],
      formats: (map['formats'] as List<dynamic>?)
              ?.map((x) => VideoFormat.fromMap(x))
              .toList() ??
          [],
    );
  }
}

class VideoFormat {
  final String formatId;
  final String? ext;
  final int? width;
  final int? height;
  final String? acodec; // Audio codec
  final String? vcodec; // Video codec
  final double? filesize;
  final String? formatNote; // e.g. "1080p"

  VideoFormat({
    required this.formatId,
    this.ext,
    this.width,
    this.height,
    this.acodec,
    this.vcodec,
    this.filesize,
    this.formatNote,
  });

  factory VideoFormat.fromMap(Map<String, dynamic> map) {
    return VideoFormat(
      formatId: map['format_id'] ?? '',
      ext: map['ext'],
      width: map['width'],
      height: map['height'],
      acodec: map['acodec'] == 'none' ? null : map['acodec'],
      vcodec: map['vcodec'] == 'none' ? null : map['vcodec'],
      filesize: (map['filesize'] as num?)?.toDouble(),
      formatNote: map['format_note'],
    );
  }

  bool get isAudioOnly => vcodec == null && acodec != null;
  bool get isVideo => vcodec != null;
  String get label {
    if (isAudioOnly) return "Audio Only (${ext ?? 'mp3'})";
    if (formatNote != null) return "$formatNote (${ext ?? 'mp4'})";
    if (height != null) return "${height}p (${ext ?? 'mp4'})";
    return formatId;
  }
}
