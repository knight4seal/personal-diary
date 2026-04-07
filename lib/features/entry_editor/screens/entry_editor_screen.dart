import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_diary/features/entry_list/providers/entry_list_provider.dart';
import 'package:personal_diary/features/entry_editor/widgets/voice_recorder_bar.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const EntryEditorScreen({super.key, this.entryId});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DateTime _selectedDate;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _isEditing = widget.entryId != null;

    if (_isEditing) {
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    final repo = ref.read(diaryRepositoryProvider);
    final entry = await repo.getEntry(int.parse(widget.entryId!));
    if (entry != null && mounted) {
      setState(() {
        _titleController.text = entry.title ?? '';
        _contentController.text = entry.content;
        _selectedDate = entry.entryDate;
        _audioFilePath = entry.audioFilePath;
      });
    }
  }

  Future<void> _pickDate() async {
    final isDark = ref.read(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: fg,
              onPrimary: bg,
              secondary: fg,
              onSecondary: bg,
              error: Colors.grey,
              onError: bg,
              surface: bg,
              onSurface: fg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(diaryRepositoryProvider);
      final title = _titleController.text.trim();
      if (_isEditing) {
        await repo.updateEntry(
              id: int.parse(widget.entryId!),
              title: title.isEmpty ? null : title,
              content: content,
              entryDate: _selectedDate,
              audioFilePath: _audioFilePath,
            );
      } else {
        await repo.createEntry(
              title: title.isEmpty ? null : title,
              content: content,
              entryDate: _selectedDate,
              audioFilePath: _audioFilePath,
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: grey, fontSize: 15),
          ),
        ),
        leadingWidth: 80,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Entry' : 'New Entry',
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? grey : fg,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date display
                      GestureDetector(
                        onTap: _pickDate,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(_selectedDate),
                            style: TextStyle(
                              color: grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      // Title field
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: fg,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title (optional)',
                          hintStyle: TextStyle(
                            color: grey.withOpacity(0.5),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Divider(color: dividerColor),
                      const SizedBox(height: 8),
                      // Content field
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          color: fg,
                          fontSize: 16,
                          height: 1.7,
                        ),
                        maxLines: null,
                        minLines: 12,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: grey.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Voice recorder bar
              VoiceRecorderBar(
                onTranscriptionComplete: (title, body, audioPath) {
                  // First sentence becomes title (if title field is empty)
                  if (title != null && _titleController.text.trim().isEmpty) {
                    _titleController.text = title;
                  } else if (title != null) {
                    // Title already has text — prepend to body
                    final fullBody = '$title $body';
                    final current = _contentController.text;
                    _contentController.text =
                        current.isEmpty ? fullBody : '$current\n$fullBody';
                  }
                  // Rest goes to body
                  if (body.isNotEmpty) {
                    final current = _contentController.text;
                    _contentController.text =
                        current.isEmpty ? body : '$current\n$body';
                  }
                  _contentController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _contentController.text.length),
                  );
                  if (audioPath != null) {
                    _audioFilePath = audioPath;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
