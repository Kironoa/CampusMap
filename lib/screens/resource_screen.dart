import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/glass_modal.dart';

class ResourcesScreen extends StatefulWidget {
  final int userId; // Added to match dashboard/assignment pattern
  const ResourcesScreen({super.key, required this.userId});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  double res(BuildContext context, double value) {
    return value * Provider.of<ThemeProvider>(context, listen: false).uiScale;
  }

  // --- ACTIONS & MODALS ---

  void _showFileOptions(Map<String, dynamic> fileData, IconData icon) {
    GlassModal.show(
      context,
      title: "FILE OPTIONS",
      barrierDismissible: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModalOption(
            icon: Icons.open_in_new_rounded,
            label: "OPEN",
            onTap: () {
              Navigator.pop(context);
              _handleFileAction(fileData);
            },
          ),
          _buildModalOption(
            icon: Icons.edit_rounded,
            label: "RENAME",
            onTap: () {
              Navigator.pop(context);
              _handleRenameAction(fileData);
            },
          ),
          _buildModalOption(
            icon: Icons.delete_outline_rounded,
            label: "DELETE",
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _handleDeleteAction(fileData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : const Color(0xFF00FF75),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _handleRenameAction(Map<String, dynamic> fileData) async {
    String? newName = await _showRenameDialog(fileData['fileName']);
    if (newName != null && newName.isNotEmpty) {
      final extension = fileData['fileName'].split('.').last;
      if (!newName.toLowerCase().endsWith('.$extension')) {
        newName = "$newName.$extension";
      }

      await _dbHelper.updateResourceName(fileData['id'], newName);
      setState(() {});
    }
  }

  Future<void> _handleDeleteAction(Map<String, dynamic> fileData) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Resource?"),
        content: Text("Delete '${fileData['fileName']}' permanently?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (fileData['localPath'] != null) {
        final file = File(fileData['localPath']);
        if (await file.exists()) await file.delete();
      }
      await _dbHelper.deleteResource(fileData['id']);
      setState(() {});
    }
  }

  Future<String?> _showRenameDialog(String currentName) async {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("File Name",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter name"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text("Save")),
          ],
        );
      },
    );
  }

  // --- UPLOAD LOGIC ---

  Future<void> _uploadResource() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      String originalName = result.files.single.name;
      String? newName = await _showRenameDialog(originalName);
      if (newName == null || newName.isEmpty) return;

      setState(() => _isLoading = true);

      try {
        final pickedFile = File(result.files.single.path!);
        final extension = originalName.split('.').last.toLowerCase();

        if (!newName.toLowerCase().endsWith('.$extension')) {
          newName = "$newName.$extension";
        }

        String category = 'others';
        if (extension == 'pdf')
          category = 'pdfs';
        else if (['doc', 'docx'].contains(extension))
          category = 'docs';
        else if (['jpg', 'jpeg', 'png'].contains(extension))
          category = 'images';

        final directory = await getApplicationDocumentsDirectory();
        final String localPath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$newName';

        await pickedFile.copy(localPath);
        // Using widget.userId to link resources to the logged-in user
        await _dbHelper.insertResource(
            widget.userId, newName, localPath, category);

        setState(() {});
      } catch (e) {
        debugPrint("Upload error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: "Search resources...", border: InputBorder.none),
                style: TextStyle(fontSize: res(context, 14)),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              )
            : Text("STUDENT RESOURCES",
                style: TextStyle(
                    fontSize: res(context, 14),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = "";
              }
            }),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: theme.hintColor,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: "PDFs"),
            Tab(icon: Icon(Icons.description), text: "Docs"),
            Tab(icon: Icon(Icons.image), text: "Images"),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFileGrid('pdfs', Icons.picture_as_pdf_outlined),
              _buildFileGrid('docs', Icons.article_outlined),
              _buildFileGrid('images', Icons.image_outlined),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadResource,
        backgroundColor: accentColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Upload",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFileGrid(String category, IconData icon) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbHelper.getLocalResources(widget.userId, category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SizedBox();

        final allFiles = snapshot.data ?? [];
        final files = allFiles.where((file) {
          final name = file['fileName']?.toString().toLowerCase() ?? "";
          return name.contains(_searchQuery);
        }).toList();

        if (files.isEmpty) {
          return _buildEmptyState(
              icon, _searchQuery.isEmpty ? "No files found" : "No matches");
        }

        return GridView.builder(
          padding: EdgeInsets.all(res(context, 16)),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileCard(files[index], icon),
        );
      },
    );
  }

  Widget _buildFileCard(Map<String, dynamic> fileData, IconData icon) {
    final theme = Theme.of(context);
    final String? localPath = fileData['localPath'];
    final bool isImage = fileData['category'] == 'images';

    return GestureDetector(
      onTap: () => _showFileOptions(fileData, icon),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(res(context, 16)),
          border:
              Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isImage && localPath != null && File(localPath).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(localPath),
                        width: 65, height: 65, fit: BoxFit.cover),
                  )
                : Icon(icon,
                    size: 42,
                    color: theme.colorScheme.primary.withOpacity(0.8)),
            SizedBox(height: res(context, 12)),
            Text(
              fileData['fileName'] ?? "Untitled",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: res(context, 12), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileAction(Map<String, dynamic> fileData) async {
    final String? path = fileData['localPath'];
    if (path != null && await File(path).exists()) {
      await OpenFilex.open(path);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("File missing")));
    }
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
