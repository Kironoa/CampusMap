import 'package:flutter/material.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'dart:ui';

class SummariesScreen extends StatefulWidget {
  final int userId;
  const SummariesScreen({super.key, required this.userId});

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _summaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    setState(() => _isLoading = true);
    // Fetching resources saved under the 'summary' category
    final data = await _dbHelper.getLocalResources(widget.userId, 'summary');
    setState(() {
      _summaries = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00FF75);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("SUMMARIES",
            style: TextStyle(
                letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _summaries.isEmpty
              ? _buildEmptyState()
              : _buildSummaryList(accentColor),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.summarize_outlined,
                size: 60, color: Colors.white10),
          ),
          const SizedBox(height: 16),
          const Text("No summaries found",
              style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text("Generate one by selecting a resource",
              style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSummaryList(Color accentColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _summaries.length,
      itemBuilder: (context, index) {
        final summary = _summaries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _viewSummaryDetails(summary),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.short_text_rounded, color: accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary['fileName'] ?? "Untitled Summary",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary['content'] ?? "No content available",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewSummaryDetails(Map<String, dynamic> summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                summary['fileName']?.toUpperCase() ?? "SUMMARY",
                style: const TextStyle(
                    color: Color(0xFF00FF75),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    summary['content'] ?? "No summary text generated.",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 15, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
