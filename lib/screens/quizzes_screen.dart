import 'package:flutter/material.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'dart:ui';

class QuizzesScreen extends StatefulWidget {
  final int userId;
  const QuizzesScreen({super.key, required this.userId});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    // Assuming your db_helper has a getQuizzes method
    // If not, this pulls generic resources categorized as 'quiz'
    final data = await _dbHelper.getLocalResources(widget.userId, 'quiz');
    setState(() {
      _quizzes = data;
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
        title: const Text("QUIZZES",
            style: TextStyle(
                letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _quizzes.isEmpty
              ? _buildEmptyState()
              : _buildQuizGrid(accentColor),
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
            child: const Icon(Icons.quiz_outlined,
                size: 60, color: Colors.white10),
          ),
          const SizedBox(height: 16),
          const Text("No quizzes generated yet",
              style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text("Go to Resources to generate one with AI",
              style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuizGrid(Color accentColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return _buildQuizCard(quiz, accentColor);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: accentColor.withOpacity(0.05),
                child: Icon(Icons.psychology_alt_rounded,
                    size: 40, color: accentColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    quiz['fileName'] ?? "Untitled Quiz",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Logic to start the actual quiz session
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("START",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
