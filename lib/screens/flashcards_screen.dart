import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:mobile_app/helper/db_helper.dart';

class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});
}

class FlashcardsScreen extends StatefulWidget {
  final String rawAIContent;
  final String title;
  final int? resourceId; // Added to link to a resource

  const FlashcardsScreen(
      {super.key,
      required this.rawAIContent,
      required this.title,
      this.resourceId});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  final database = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _parseAndSaveContent();
  }

  void _parseAndSaveContent() async {
    List<Flashcard> tempCards = [];
    final lines = widget.rawAIContent.split('\n');
    String currentQ = "";
    String currentA = "";

    for (var line in lines) {
      if (line.toLowerCase().startsWith('q:') ||
          line.toLowerCase().startsWith('question:')) {
        currentQ = line.replaceFirst(RegExp(r'^[Qq](uestion)?:?\s*'), '');
      } else if (line.toLowerCase().startsWith('a:') ||
          line.toLowerCase().startsWith('answer:')) {
        currentA = line.replaceFirst(RegExp(r'^[Aa](nswer)?:?\s*'), '');
        if (currentQ.isNotEmpty && currentA.isNotEmpty) {
          tempCards.add(Flashcard(question: currentQ, answer: currentA));
          currentQ = "";
          currentA = "";
        }
      }
    }

    if (tempCards.isNotEmpty) {
      // Optional: Save to DB here so it persists in the "Summaries/Study" tab
      // await _dbHelper.saveFlashcardSet(widget.resourceId, widget.rawAIContent);
      setState(() => _cards = tempCards);
    } else {
      setState(() {
        _cards = [
          Flashcard(
              question: "No cards found",
              answer: "Try regenerating with clearer content.")
        ];
      });
    }
  }

  void _nextCard() =>
      setState(() => _currentIndex = (_currentIndex + 1) % _cards.length);
  void _prevCard() => setState(() =>
      _currentIndex = (_currentIndex - 1 + _cards.length) % _cards.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _cards.isEmpty ? 0.0 : (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title.toUpperCase(),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: theme.colorScheme.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text("${_currentIndex + 1} / ${_cards.length}",
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.bold)),
          const Spacer(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width * 0.85,
            child: FlipCard(
              direction: FlipDirection.HORIZONTAL,
              front: _buildCardFace(
                  _cards[_currentIndex].question, "QUESTION", theme, true),
              back: _buildCardFace(
                  _cards[_currentIndex].answer, "ANSWER", theme, false),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavBtn(
                    Icons.arrow_back_ios_new, _prevCard, _currentIndex > 0),
                _buildNavBtn(Icons.arrow_forward_ios, _nextCard,
                    _currentIndex < _cards.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFace(
      String text, String label, ThemeData theme, bool isFront) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isFront
            ? const Color(0xFF1E1E1E)
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isFront
                ? Colors.white10
                : theme.colorScheme.primary.withOpacity(0.5),
            width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: isFront ? Colors.white38 : theme.colorScheme.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Expanded(
              child: Center(
                  child: SingleChildScrollView(
                      child: Text(text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.5))))),
          const SizedBox(height: 20),
          const Text("Tap to flip",
              style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNavBtn(IconData icon, VoidCallback onPressed, bool enabled) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon:
          Icon(icon, color: enabled ? Colors.white : Colors.white10, size: 30),
    );
  }
}
