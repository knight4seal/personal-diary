import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_diary/core/extensions/date_extensions.dart';
import 'package:personal_diary/features/settings/providers/settings_provider.dart';
import 'package:personal_diary/services/selfie_service.dart';

/// Timeline grid showing all selfies over time.
/// Accessible from Settings — subtle, not prominent.
class SelfieTimelineScreen extends ConsumerStatefulWidget {
  const SelfieTimelineScreen({super.key});

  @override
  ConsumerState<SelfieTimelineScreen> createState() =>
      _SelfieTimelineScreenState();
}

class _SelfieTimelineScreenState extends ConsumerState<SelfieTimelineScreen> {
  final SelfieService _selfieService = SelfieService();
  List<DateTime> _dates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelfies();
  }

  Future<void> _loadSelfies() async {
    final dates = await _selfieService.getAllSelfieDates();
    if (mounted) {
      setState(() {
        _dates = dates;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final fg = isDark ? Colors.white : Colors.black;
    final bg = isDark ? Colors.black : Colors.white;
    final grey = Colors.grey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Selfie Timeline',
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: fg),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _loading
              ? Center(
                  child:
                      CircularProgressIndicator(color: fg, strokeWidth: 1))
              : _dates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                color: grey, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'No selfies yet',
                              style: TextStyle(color: grey, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the small circle next to the date in Daily View to take your first selfie.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: grey, fontSize: 13, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Text(
                            '${_dates.length} selfie${_dates.length == 1 ? '' : 's'}',
                            style: TextStyle(color: grey, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _dates.length,
                            itemBuilder: (context, index) {
                              return _SelfieGridItem(
                                date: _dates[index],
                                selfieService: _selfieService,
                                fg: fg,
                                grey: grey,
                                isDark: isDark,
                                onTap: () => _showFullSelfie(
                                    context, _dates[index], fg, bg, grey),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  void _showFullSelfie(BuildContext context, DateTime date, Color fg, Color bg,
      Color grey) async {
    final path = await _selfieService.getSelfie(date);
    if (path == null || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                date.formattedDate,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(path),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: TextStyle(color: grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfieGridItem extends StatefulWidget {
  final DateTime date;
  final SelfieService selfieService;
  final Color fg;
  final Color grey;
  final bool isDark;
  final VoidCallback onTap;

  const _SelfieGridItem({
    required this.date,
    required this.selfieService,
    required this.fg,
    required this.grey,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SelfieGridItem> createState() => _SelfieGridItemState();
}

class _SelfieGridItemState extends State<_SelfieGridItem> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await widget.selfieService.getSelfie(widget.date);
    if (mounted) setState(() => _path = path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          Expanded(
            child: _path != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(_path!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: widget.isDark
                          ? Colors.grey[900]
                          : Colors.grey[100],
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.date.month}/${widget.date.day}',
            style: TextStyle(color: widget.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
