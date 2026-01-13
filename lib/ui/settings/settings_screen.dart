import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Settings"),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildSectionHeader("General"),
                _buildSettingItem(
                  context,
                  title: "Appearance",
                  subtitle: "Dark Mode",
                  icon: CupertinoIcons.moon_fill,
                  onTap: () {},
                ),
                _buildSettingItem(
                  context,
                  title: "Language",
                  subtitle: "English",
                  icon: CupertinoIcons.globe,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSectionHeader("Downloads"),
                _buildSettingItem(
                  context,
                  title: "Download Location",
                  subtitle: "/Internal Storage/Clivon",
                  icon: CupertinoIcons.folder_fill,
                  onTap: () {},
                ),
                _buildSettingItem(
                  context,
                  title: "Quality",
                  subtitle: "Best Available (4K)",
                  icon: CupertinoIcons.slider_horizontal_3,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSectionHeader("Network & Auth"),
                _buildSettingItem(
                  context,
                  title: "Import Cookies",
                  subtitle: "Required for Instagram/TikTok",
                  icon: CupertinoIcons.lock_shield_fill,
                  onTap: () => _importCookies(context),
                ),
                _buildDivider(),
                _buildSectionHeader("About"),
                _buildSettingItem(
                  context,
                  title: "Version",
                  subtitle: "1.0.0 (Alpha)",
                  icon: CupertinoIcons.info_circle_fill,
                  onTap: () {},
                ),
                _buildSettingItem(
                  context,
                  title: "Developer",
                  subtitle: "KannanTech",
                  icon: CupertinoIcons.hammer_fill,
                  onTap: () {},
                ),
                _buildSettingItem(
                  context,
                  title: "License",
                  subtitle: "Proprietary",
                  icon: CupertinoIcons.doc_text_fill,
                  onTap: () {},
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(CupertinoIcons.chevron_forward,
            color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Divider(color: Color(0xFF2C2C2C), height: 1),
    );
  }

  Future<void> _importCookies(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        File sourceFile = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final File destinationFile = File('${directory.path}/cookies.txt');
        await sourceFile.copy(destinationFile.path);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cookies imported successfully!"),
              backgroundColor: Color(0xFF6C63FF),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error importing cookies: $e")),
        );
      }
    }
  }
}
