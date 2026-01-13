import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/repository_provider.dart';
import '../../features/downloads/data/models/download_item.dart';
import '../player/video_player_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Monitor database updates in real-time
    final downloadsStream = ref.watch(downloadRepositoryProvider).watchAllDownloads();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Library"),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash),
            onPressed: () {
              // ref.read(downloadRepositoryProvider).deleteAll();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DownloadItem>>(
        stream: downloadsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final items = snapshot.data!;
          
          if (items.isEmpty) return _buildEmptyState("No downloads yet");

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                subtitle: _buildSubtitle(item),
                leading: _buildLeadingIcon(item),
                trailing: item.status == DownloadStatus.downloading 
                   ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(value: item.progress / 100))
                   : const Icon(CupertinoIcons.play_circle, color: Colors.white),
                onTap: () {
                   if (item.status == DownloadStatus.completed) {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => VideoPlayerScreen(filePath: "${item.downloadPath}/${item.title}.mp4"),
                       ),
                     );
                   }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubtitle(DownloadItem item) {
    if (item.status == DownloadStatus.downloading) {
      final speed = item.speed ?? "";
      final eta = item.eta != null ? "• ETA ${item.eta}" : "";
      return Text(
        "${item.progress.toStringAsFixed(1)}% • $speed $eta", 
        style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.bold)
      );
    }
    return Text("${item.status.name} • ${item.downloadPath}", style: TextStyle(color: Colors.grey[400], fontSize: 12));
  }

  Widget _buildLeadingIcon(DownloadItem item) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          image: item.thumbnailUrl != null 
             ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
             : null
        ),
        child: item.thumbnailUrl == null ? const Icon(Icons.video_file, color: Colors.white) : null,
      );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.square_stack_3d_up,
            size: 64,
            color: Colors.grey.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
