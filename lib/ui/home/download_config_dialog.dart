
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/downloads/data/models/video_metadata.dart';

class DownloadConfigDialog extends StatefulWidget {
  final VideoMetadata metadata;

  const DownloadConfigDialog({super.key, required this.metadata});

  @override
  State<DownloadConfigDialog> createState() => _DownloadConfigDialogState();
}

class _DownloadConfigDialogState extends State<DownloadConfigDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoFormat? _selectedFormat;
  bool _isAudioOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Default selection logic
    final bestVideo = _getBestVideo();
    if (bestVideo != null) {
      _selectedFormat = bestVideo;
      _isAudioOnly = false;
    }
  }

  List<VideoFormat> get _videoFormats => widget.metadata.formats
      .where((f) => f.isVideo && (f.ext == 'mp4' || f.ext == 'mkv'))
      .toList()
      ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));

  List<VideoFormat> get _audioFormats => widget.metadata.formats
      .where((f) => f.isAudioOnly || f.acodec != null) // simplified
      .toList();
      
  VideoFormat? _getBestVideo() {
    if (_videoFormats.isNotEmpty) return _videoFormats.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Thumbnail & Info
          _buildHeader(context),
          
          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.videocam), text: "Video"),
              Tab(icon: Icon(Icons.audiotrack), text: "Audio"),
            ],
            onTap: (index) {
                setState(() {
                    if (index == 0) {
                         _isAudioOnly = false;
                         if (_videoFormats.isNotEmpty) _selectedFormat = _videoFormats.first;
                    } else {
                        _isAudioOnly = true;
                         // For audio, we usually let yt-dlp pick best, or select the first one
                         // But typically we pass 'bestaudio' or '-x'. 
                         // For now let's just select null to imply "Best Audio" or a specific one if needed.
                         _selectedFormat = null; 
                    }
                });
            },
          ),
          
          // Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormatList(_videoFormats, isAudio: false),
                _buildAudioOptions(),
              ],
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.pop(context, DownloadConfigResult(
                      formatId: _selectedFormat?.formatId,
                      isAudioOnly: _isAudioOnly,
                    ));
                  },
                  child: const Text("Download", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
           ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.metadata.thumbnail != null
                ? Image.network(widget.metadata.thumbnail!, width: 80, height: 45, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(width: 80, height: 45, color: Colors.grey))
                : Container(width: 80, height: 45, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.metadata.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (widget.metadata.duration != null)
                    Text(_formatDuration(widget.metadata.duration!), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    return d.toString().split('.').first.padLeft(8, "0");
  }

  Widget _buildFormatList(List<VideoFormat> formats, {required bool isAudio}) {
    if (formats.isEmpty) return const Center(child: Text("No formats found", style: TextStyle(color: Colors.grey)));
    
    return ListView.builder(
      itemCount: formats.length,
      itemBuilder: (context, index) {
        final f = formats[index];
        final isSelected = _selectedFormat == f;
        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          leading: Icon(isAudio ? Icons.audiotrack : Icons.hd, 
            color: isSelected ? AppTheme.primaryColor : Colors.grey),
          title: Text(f.label, style: const TextStyle(color: Colors.white)),
          subtitle: f.filesize != null 
            ? Text("${(f.filesize! / 1024 / 1024).toStringAsFixed(1)} MB", style: TextStyle(color: Colors.grey[400]))
            : null,
          onTap: () {
            setState(() {
              _selectedFormat = f;
              _isAudioOnly = isAudio;
            });
          },
        );
      },
    );
  }

  Widget _buildAudioOptions() {
      // Simple option for now: "Best Audio"
      return Column(
          children: [
              ListTile(
                  title: const Text("Best Quality (Auto)", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.music_note, color: AppTheme.primaryColor),
                  subtitle: const Text("Convert to MP3", style: TextStyle(color: Colors.grey)),
                  selected: _selectedFormat == null && _isAudioOnly,
                  onTap: () {
                      setState(() {
                          _selectedFormat = null; // null means 'best'
                          _isAudioOnly = true;
                      });
                  },
              )
          ]
      );
  }
}

class DownloadConfigResult {
  final String? formatId;
  final bool isAudioOnly;

  DownloadConfigResult({this.formatId, required this.isAudioOnly});
}
