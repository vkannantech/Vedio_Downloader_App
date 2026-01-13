import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/di/logic_provider.dart';
import '../../core/di/repository_provider.dart';
import '../../features/downloads/data/models/download_item.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'download_config_dialog.dart';
import 'loading_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkSharedText();
  }

  Future<void> _checkSharedText() async {
    final native = ref.read(nativeDownloaderProvider);
    final text = await native.getSharedText();
    if (text != null && text.isNotEmpty) {
      if (mounted) _handleQuickPaste(context, ref, initialUrl: text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome Back,",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
          const SizedBox(height: 4),
          const Text(
            "Start Downloading",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1),
          const SizedBox(height: 24),
          _buildActionCard(
            context,
            title: "Quick Paste",
            subtitle: "Paste link to download instantly",
            icon: Icons.content_paste_rounded,
            color: const Color(0xFF6C63FF),
            onTap: () => _handleQuickPaste(context, ref),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 16),
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 12),
          _buildRecentActivity(ref).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Future<void> _handleQuickPaste(BuildContext context, WidgetRef ref, {String? initialUrl}) async {
    // 1. Check Permissions
    bool isGranted = false;
    if (await Permission.storage.request().isGranted) {
      isGranted = true;
    } else if (await Permission.manageExternalStorage.request().isGranted) {
      isGranted = true;
    } else if (await Permission.photos.request().isGranted && await Permission.videos.request().isGranted) {
       // Android 13+ partial access
       isGranted = true;
    }

    if (!isGranted) {
      if (context.mounted) {
         showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Permission Needed", style: TextStyle(color: Colors.white)),
            content: const Text("Clivon needs access to storage to save your downloads.", style: TextStyle(color: Colors.grey)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              TextButton(onPressed: () => openAppSettings(), child: const Text("Settings")),
            ],
          ),
        );
      }
      return;
    }

    // 2. Get URL
    if (!context.mounted) return;
    String? url = initialUrl;
    if (url == null) {
        url = await showDialog<String>(
          context: context,
          builder: (ctx) => _buildUrlDialog(ctx, initialValue: ""),
        );
    } else {
         url = await showDialog<String>(
          context: context,
          builder: (ctx) => _buildUrlDialog(ctx, initialValue: url),
        );
    }

    if (url != null && url.isNotEmpty) {
      // 3. Fetch Metadata
      if (!context.mounted) return;
      
      // Show Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const LoadingDialog(status: "Fetching Info..."),
      );
      
      final native = ref.read(nativeDownloaderProvider);
      final metaResult = await native.fetchMetadata(url!);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      await metaResult.fold(
        (error) async {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching info: $error")));
        }, 
        (metadata) async {
             // 4. Show Config Dialog
             final config = await showDialog<DownloadConfigResult>(
                 context: context,
                 builder: (ctx) => DownloadConfigDialog(metadata: metadata),
             );
             
             if (config == null) return; 
             
             // 5. Add to Queue
             String baseDir = "/storage/emulated/0/Download/Clivon";
             if (config.isAudioOnly) {
               baseDir = "$baseDir/Audio";
             } else {
               baseDir = "$baseDir/Video";
             }

             final newItem = DownloadItem()
                ..url = url!
                ..title = metadata.title
                ..thumbnailUrl = metadata.thumbnail
                ..duration = metadata.duration?.toString()
                ..createdAt = DateTime.now()
                ..downloadPath = baseDir
                ..formatId = config.formatId
                ..isAudioOnly = config.isAudioOnly;

              final repo = ref.read(downloadRepositoryProvider);
              final result = await repo.addDownload(newItem);
              
              if (context.mounted) {
                result.fold(
                  (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $l"))),
                  (r) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download Queued!"))),
                );
              }
        }
      );
    }
  }

  Widget _buildUrlDialog(BuildContext context, {String? initialValue}) {
    String value = initialValue ?? "";
    final controller = TextEditingController(text: value);
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Download", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Paste Link (YouTube, TikTok...)",
                  hintStyle: TextStyle(color: Colors.grey),
                  icon: Icon(Icons.link, color: Color(0xFF6C63FF)),
                ),
                onChanged: (v) => value = v,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    // Watch last 3 items
    final stream = ref.watch(downloadRepositoryProvider).watchAllDownloads();
    
    return StreamBuilder<List<DownloadItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();
        
        final list = snapshot.data!.take(3).toList();
        return Column(
          children: list.map((item) => ListTile(
            title: Text(item.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(item.status.name, style: const TextStyle(color: Colors.grey)),
            leading: const Icon(Icons.video_file, color: Colors.white),
            trailing: CircularProgressIndicator(value: item.progress, strokeWidth: 2),
            contentPadding: EdgeInsets.zero,
          )).toList(),
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.download_done_rounded,
                size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              "No downloads yet",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
