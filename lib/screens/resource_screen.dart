import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/glass_modal.dart';
import 'package:mobile_app/services/offline_ai_service.dart';
import 'package:mobile_app/services/file_extraction_service.dart';
import 'package:mobile_app/screens/flashcards_screen.dart';
import 'package:mobile_app/screens/quizzes_screen.dart';
import 'package:mobile_app/screens/summaries_screen.dart';

class ResourcesScreen extends StatefulWidget {
  final int userId;
  const ResourcesScreen({super.key, required this.userId});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper();
  final _offlineAI = OfflineAIService();

  bool _isLoading = false;
  String _currentCategory = 'pdf';
  List<Map<String, dynamic>> _resources = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) _currentCategory = 'pdf';
          if (_tabController.index == 1) _currentCategory = 'doc';
          if (_tabController.index == 2) _currentCategory = 'jpg';
        });
        _loadResources();
      }
    });
    _loadResources();
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

  // --- UPDATED AI LOGIC ---
  void _handleAIAction(
      Map<String, dynamic> data, String type, Color accentColor) async {
    String textContent = data['content'] ?? data['description'] ?? "";
    String title = data['fileName'] ?? "Study Material";
    int resourceId = data['id'];

    if (textContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No text content found to analyze.")));
      return;
    }

    if (type == "SUMMARY") {
      String prompt = _offlineAI.buildSummaryPrompt(textContent);
      _processAIRequest(prompt, title, resourceId, type, accentColor);
    } else {
      // For FLASHCARDS and QUIZ, ask how many
      _showQuantityDialog(textContent, title, resourceId, type, accentColor);
    }
  }

  void _showQuantityDialog(String content, String title, int resourceId,
      String type, Color accentColor) {
    int count = 5;
    String label = type == "FLASHCARDS" ? "Flashcards" : "Quiz Questions";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$label Count",
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "How many to generate?",
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor)),
          ),
          onChanged: (v) => count = int.tryParse(v) ?? 5,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () {
              Navigator.pop(context);
              String prompt = type == "FLASHCARDS"
                  ? _offlineAI.buildFlashcardPrompt(content, count: count)
                  : _offlineAI.buildQuizPrompt(content, count);
              _processAIRequest(prompt, title, resourceId, type, accentColor);
            },
            child:
                const Text("GENERATE", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _processAIRequest(String prompt, String title, int resourceId,
      String type, Color accentColor) async {
    setState(() => _isLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Processing with Student Pal AI...",
              style: TextStyle(fontSize: res(context, 14))),
          backgroundColor: accentColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating),
    );

    try {
      // Calls the OfflineAIService which checks cache -> Online -> Local
      final aiResponse = await _offlineAI.generateContent(
        prompt: prompt,
        resourceId: resourceId,
        type: type,
      );

      if (!mounted) return;

      // Navigate based on the type of generation
      Widget targetScreen;
      if (type == "FLASHCARDS") {
        targetScreen = FlashcardsScreen(rawAIContent: aiResponse, title: title);
      } else if (type == "QUIZ") {
        targetScreen = QuizzesScreen(userId: widget.userId);
      } else {
        targetScreen = SummariesScreen(userId: widget.userId);
      }

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => targetScreen));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("AI Error: $e"), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI COMPONENTS (UNCHANGED) ---

  void _showResourceOptions(Map<String, dynamic> data, Color accentColor) {
    GlassModal.show(
      context,
      title: (data['fileName'] ?? "OPTIONS").toUpperCase(),
      barrierDismissible: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModalOption(
              icon: Icons.open_in_new_rounded,
              label: "OPEN FILE",
              accentColor: accentColor,
              onTap: () {
                Navigator.pop(context);
                _handleFileAction(data);
              }),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: res(context, 16)),
              child: const Divider(color: Colors.white10)),
          _buildModalOption(
              icon: Icons.summarize_rounded,
              label: "GENERATE SUMMARY",
              accentColor: accentColor,
              onTap: () {
                Navigator.pop(context);
                _handleAIAction(data, "SUMMARY", accentColor);
              }),
          _buildModalOption(
              icon: Icons.style_rounded,
              label: "GENERATE FLASHCARDS",
              accentColor: accentColor,
              onTap: () {
                Navigator.pop(context);
                _handleAIAction(data, "FLASHCARDS", accentColor);
              }),
          _buildModalOption(
              icon: Icons.quiz_rounded,
              label: "GENERATE QUIZ",
              accentColor: accentColor,
              onTap: () {
                Navigator.pop(context);
                _handleAIAction(data, "QUIZ", accentColor);
              }),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: res(context, 16)),
              child: const Divider(color: Colors.white10)),
          _buildModalOption(
              icon: Icons.delete_outline_rounded,
              label: "DELETE PERMANENTLY",
              accentColor: accentColor,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _handleDeleteAction(data);
              }),
        ],
      ),
    );
  }

  Widget _buildModalOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color accentColor,
      bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
          horizontal: res(context, 24), vertical: res(context, 4)),
      leading: Container(
        padding: EdgeInsets.all(res(context, 8)),
        decoration: BoxDecoration(
            color: isDestructive
                ? Colors.redAccent.withOpacity(0.1)
                : accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(res(context, 10))),
        child: Icon(icon,
            size: res(context, 20),
            color: isDestructive ? Colors.redAccent : accentColor),
      ),
      title: Text(label,
          style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: res(context, 13),
              letterSpacing: 0.5)),
    );
  }

  Future<void> _loadResources() async {
    final data =
        await _dbHelper.getLocalResources(widget.userId, _currentCategory);
    setState(() {
      _resources = data;
    });
  }

  Future<void> _handleDeleteAction(Map<String, dynamic> fileData) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text("Delete?", style: TextStyle(fontSize: res(context, 18))),
        content: Text("Permanently remove ${fileData['fileName']}?",
            style: TextStyle(fontSize: res(context, 14))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      if (fileData['localPath'] != null) {
        final file = File(fileData['localPath']);
        if (await file.exists()) await file.delete();
      }
      await _dbHelper.deleteResource(fileData['id']);
      _loadResources();
    }
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

  Future<void> _uploadResource() async {
    final result = await FilePicker.pickFiles(
        // Updated API call
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg']);
    if (result != null && result.files.single.path != null) {
      String originalName = result.files.single.name;
      setState(() => _isLoading = true);
      try {
        final directory = await getApplicationDocumentsDirectory();
        final String localPath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName';
        await File(result.files.single.path!).copy(localPath);
        String ext = originalName.split('.').last.toLowerCase();
        String category = (ext == 'pdf')
            ? 'pdf'
            : (ext == 'doc' || ext == 'docx')
                ? 'doc'
                : 'jpg';
        String extractedText =
            await FileExtractionService.extractText(localPath, category);
        await _dbHelper.insertResource(
            widget.userId, originalName, localPath, category,
            content: extractedText);
        _loadResources();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to upload: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.currentAccentColor;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: ClipRRect(
        borderRadius:
            BorderRadius.horizontal(right: Radius.circular(res(context, 30))),
        child: Drawer(
          backgroundColor: const Color(0xFF141414).withOpacity(0.9),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  margin: EdgeInsets.zero,
                  decoration:
                      BoxDecoration(color: accentColor.withOpacity(0.05)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(res(context, 10)),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Icon(Icons.auto_awesome_rounded,
                            color: accentColor, size: res(context, 30)),
                      ),
                      SizedBox(height: res(context, 15)),
                      Text("STUDY CENTER",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: res(context, 18))),
                    ],
                  ),
                ),
                SizedBox(height: res(context, 10)),
                _buildStudyDrawerItem(Icons.style_rounded, "Flashcards", () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FlashcardsScreen(
                              rawAIContent: "", title: "Flashcards")));
                }, accentColor),
                _buildStudyDrawerItem(Icons.quiz_rounded, "Quizzes", () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              QuizzesScreen(userId: widget.userId)));
                }, accentColor),
                _buildStudyDrawerItem(Icons.summarize_rounded, "Summaries", () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SummariesScreen(userId: widget.userId)));
                }, accentColor),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: EdgeInsets.all(res(context, 8.0)),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: res(context, 20), color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: _isSearching
            ? Container(
                height: res(context, 40),
                padding: EdgeInsets.symmetric(horizontal: res(context, 15)),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(res(context, 20))),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                      color: Colors.white, fontSize: res(context, 14)),
                  decoration: const InputDecoration(
                      hintText: "Search resources...",
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              )
            : Text("RESOURCES",
                style: TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    fontSize: res(context, 16))),
        actions: [
          IconButton(
            icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                size: res(context, 24),
                color: Colors.white70),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = "";
              }
            }),
          ),
          SizedBox(width: res(context, 8)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white38,
          labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: res(context, 12),
              letterSpacing: 1),
          tabs: const [
            Tab(text: "PDFs"),
            Tab(text: "DOCS"),
            Tab(text: "IMAGES")
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildFileGrid('pdf', Icons.picture_as_pdf_rounded, accentColor),
              _buildFileGrid('doc', Icons.description_rounded, accentColor),
              _buildFileGrid('jpg', Icons.image_rounded, accentColor),
            ],
          ),
          if (_isLoading)
            Container(
                color: Colors.black45,
                child: Center(
                    child: CircularProgressIndicator(color: accentColor))),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.fromLTRB(
            res(context, 20), 0, res(context, 20), res(context, 20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: res(context, 56),
              width: res(context, 56),
              child: FloatingActionButton(
                heroTag: "burgerBtn",
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(res(context, 18))),
                child: Icon(Icons.menu_open_rounded,
                    color: Colors.white, size: res(context, 24)),
              ),
            ),
            FloatingActionButton.extended(
              heroTag: "uploadBtn",
              onPressed: _uploadResource,
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(res(context, 18))),
              icon: Icon(Icons.add_rounded,
                  color: Colors.black, size: res(context, 28)),
              label: Text("UPLOAD",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: res(context, 14),
                      letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyDrawerItem(
      IconData icon, String title, VoidCallback onTap, Color accent) {
    return ListTile(
      leading: Icon(icon, color: accent, size: res(context, 24)),
      title: Text(title,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: res(context, 14))),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(res(context, 15))),
      contentPadding: EdgeInsets.symmetric(horizontal: res(context, 20)),
    );
  }

  Widget _buildFileGrid(String category, IconData icon, Color accent) {
    final files = _resources
        .where((f) =>
            f['fileName'].toString().toLowerCase().contains(_searchQuery))
        .toList();
    if (files.isEmpty)
      return _buildEmptyState(icon, "No $category files found");
    return GridView.builder(
      padding: EdgeInsets.all(res(context, 20)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: res(context, 15),
          crossAxisSpacing: res(context, 15),
          childAspectRatio: 0.82),
      itemCount: files.length,
      itemBuilder: (context, index) =>
          _buildResourceCard(files[index], icon, index, accent),
    );
  }

  Widget _buildResourceCard(
      Map<String, dynamic> data, IconData icon, int index, Color accentColor) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) => Transform.scale(
          scale: value, child: Opacity(opacity: value, child: child)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(res(context, 24)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(res(context, 24)),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: accentColor.withOpacity(0.03),
                  child: Icon(icon,
                      size: res(context, 48),
                      color: accentColor.withOpacity(0.8)),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(res(context, 12), res(context, 8),
                    res(context, 12), res(context, 4)),
                child: Text(data['fileName'] ?? "Untitled",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: res(context, 12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: res(context, 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCardAction(Icons.visibility_rounded,
                        () => _handleFileAction(data), Colors.white38),
                    SizedBox(width: res(context, 8)),
                    _buildCardAction(
                        Icons.auto_awesome_rounded,
                        () => _showResourceOptions(data, accentColor),
                        accentColor),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(res(context, 12)),
      child: Container(
        padding: EdgeInsets.all(res(context, 8)),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(res(context, 12))),
        child: Icon(icon, size: res(context, 18), color: color),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(res(context, 20)),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02), shape: BoxShape.circle),
            child: Icon(icon, size: res(context, 60), color: Colors.white10),
          ),
          SizedBox(height: res(context, 16)),
          Text(message,
              style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.w500,
                  fontSize: res(context, 14),
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}
