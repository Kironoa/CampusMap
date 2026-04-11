import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/theme_provider.dart';
import 'package:mobile_app/helper/db_helper.dart';
import 'package:mobile_app/widgets/text_field.dart';

double res(BuildContext context, double value) {
  final provider = Provider.of<ThemeProvider>(context, listen: false);
  return value * provider.uiScale;
}

class NotesScreen extends StatefulWidget {
  final int userId;
  const NotesScreen({super.key, required this.userId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final dbHelper = DatabaseHelper();
  Future<List<Map<String, dynamic>>>? _notesFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = dbHelper.getNotes(widget.userId);
    });
  }

  void _showGlassAlert(String message, {Color? color}) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _GlassAlertAnimated(
        message: message,
        themeColor: color ?? theme.colorScheme.primary,
        onDismiss: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "STUDY NOTES",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: res(context, 16),
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.grid_view_rounded, color: accentColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _notesFuture == null
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: accentColor));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) return _buildEmptyState(theme);

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    res(context, 20),
                    res(context, 10),
                    res(context, 20),
                    res(context, 100),
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) =>
                      _buildNoteTile(data[index], index, data.length),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteForm(),
        backgroundColor: accentColor,
        elevation: 4,
        icon: Icon(Icons.note_add_rounded,
            color: Colors.white, size: res(context, 20)),
        label: Text(
          "NEW NOTE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: res(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(Map<String, dynamic> item, int index, int totalItems) {
    final theme = Theme.of(context);
    final dateStr = item['dateCreated'] ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: res(context, 12),
                height: res(context, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: res(context, 2)),
                ),
              ),
              Expanded(
                child: Container(
                  width: res(context, 2),
                  color: index == totalItems - 1
                      ? Colors.transparent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          SizedBox(width: res(context, 20)),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: res(context, 20)),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(res(context, 20)),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(res(context, 20)),
                child: InkWell(
                  onTap: () => _viewNoteDetails(item),
                  child: Padding(
                    padding: EdgeInsets.all(res(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: res(context, 10),
                          ),
                        ),
                        SizedBox(height: res(context, 4)),
                        Text(
                          item['title'] ?? "Untitled Note",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: res(context, 17),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: res(context, 6)),
                        Text(
                          item['description'] ?? "No content provided.",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: res(context, 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewNoteDetails(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final dateStr = item['dateCreated'] ?? DateTime.now().toIso8601String();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: EdgeInsets.all(res(context, 25)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(res(context, 30))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: res(context, 40),
                height: res(context, 4),
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10)),
              ),
              SizedBox(height: res(context, 25)),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Text(
                        item['title'] ?? "Untitled Note",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: res(context, 22),
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: res(context, 20)),
                      _detailItem(Icons.calendar_today_rounded, "Created On",
                          formattedDate),
                      _detailItem(Icons.notes_rounded, "Content",
                          item['description'] ?? "No content provided."),
                    ],
                  ),
                ),
              ),
              SizedBox(height: res(context, 30)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: res(context, 15)),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(res(context, 12))),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(item['id']);
                      },
                      child: Text("DELETE",
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 14))),
                    ),
                  ),
                  SizedBox(width: res(context, 15)),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding:
                            EdgeInsets.symmetric(vertical: res(context, 15)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(res(context, 12))),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showNoteForm(note: item);
                      },
                      child: Text("EDIT NOTE",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: res(context, 14),
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: res(context, 20)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int noteId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(res(context, 20))),
          title: Text("Delete Note?",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: res(context, 18))),
          content: Text("This action cannot be undone.",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: res(context, 14))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL",
                  style: TextStyle(
                      color: theme.hintColor, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(res(context, 10))),
              ),
              onPressed: () async {
                await dbHelper.deleteNote(noteId);
                Navigator.pop(context);
                _refreshNotes();
                _showGlassAlert("Note Deleted", color: Colors.redAccent);
              },
              child: const Text("DELETE",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: res(context, 15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: theme.colorScheme.secondary, size: res(context, 20)),
          SizedBox(width: res(context, 15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: res(context, 10),
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary
                            .withValues(alpha: 0.7))),
                Text(value,
                    style: TextStyle(
                        fontSize: res(context, 14),
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_rounded,
                size: res(context, 80),
                color: theme.hintColor.withValues(alpha: 0.2)),
            Text("Your notebook is empty",
                style: TextStyle(
                    color: theme.hintColor, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showNoteForm({Map<String, dynamic>? note}) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: note?['title'] ?? "");
    final contentController =
        TextEditingController(text: note?['description'] ?? "");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Crucial for keyboard space
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          // Pushes the modal up when the keyboard appears
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(res(context, 25)),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(res(context, 30))),
            ),
            child: SingleChildScrollView(
              // Prevents overflow when space is limited
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: res(context, 20)),
                  Text(note == null ? "NEW NOTE" : "EDIT NOTE",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: res(context, 18))),
                  SizedBox(height: res(context, 20)),
                  CustomTextField(
                      controller: titleController,
                      hintText: "Note Title",
                      prefixIcon: Icons.title_rounded),
                  SizedBox(height: res(context, 15)),
                  CustomTextField(
                      controller: contentController,
                      hintText: "Start writing...",
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 8), // Adjusted maxlines for better fit
                  SizedBox(height: res(context, 25)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("CANCEL",
                              style: TextStyle(color: theme.hintColor)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (titleController.text.isNotEmpty) {
                              String message = "";
                              if (note == null) {
                                await dbHelper.insertNote(
                                    widget.userId,
                                    titleController.text,
                                    contentController.text);
                                message = "Note Saved Successfully!";
                              } else {
                                await dbHelper.updateNote(
                                    note['id'],
                                    titleController.text,
                                    contentController.text);
                                message = "Note Updated!";
                              }
                              Navigator.pop(context);
                              _refreshNotes();
                              _showGlassAlert(message);
                            }
                          },
                          child: Text(note == null ? "SAVE" : "UPDATE",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: res(context, 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassAlertAnimated extends StatefulWidget {
  final String message;
  final Color themeColor;
  final VoidCallback onDismiss;
  const _GlassAlertAnimated(
      {required this.message,
      required this.themeColor,
      required this.onDismiss});

  @override
  State<_GlassAlertAnimated> createState() => _GlassAlertAnimatedState();
}

class _GlassAlertAnimatedState extends State<_GlassAlertAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: res(context, 50)),
            padding: EdgeInsets.symmetric(
                vertical: res(context, 20), horizontal: res(context, 25)),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(res(context, 20)),
              boxShadow: [
                BoxShadow(
                    color: widget.themeColor.withValues(alpha: 0.4),
                    blurRadius: 20)
              ],
            ),
            child: Text(widget.message,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: res(context, 14))),
          ),
        ),
      ),
    );
  }
}
