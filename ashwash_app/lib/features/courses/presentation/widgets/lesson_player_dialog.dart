import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/course_model.dart';

class LessonPlayerDialog extends StatefulWidget {
  final CourseLesson lesson;
  final VoidCallback onCompleted;

  const LessonPlayerDialog({
    Key? key,
    required this.lesson,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<LessonPlayerDialog> createState() => _LessonPlayerDialogState();
}

class _LessonPlayerDialogState extends State<LessonPlayerDialog> {
  bool _isPlaying = false;
  double _audioProgress = 0.3;

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final Uri uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        final Uri uri = Uri.parse(urlString);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening media link: $urlString')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content Display Based on Lesson Type
            if (lesson.type == 'video') ...[
              GestureDetector(
                onTap: () => _launchUrl(lesson.contentUrl),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lesson.duration,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _launchUrl(lesson.contentUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Play Full Video (HD Stream)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ] else if (lesson.type == 'audio') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Slider(
                      value: _audioProgress,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _audioProgress = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('04:12', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(lesson.duration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      iconSize: 52,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() => _isPlaying = !_isPlaying);
                        _launchUrl(lesson.contentUrl);
                      },
                    ),
                  ],
                ),
              ),
            ] else if (lesson.type == 'pdf') ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 54, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(lesson.contentUrl),
                      icon: const Icon(Icons.file_download_rounded),
                      label: const Text('Open / Download PDF Guide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  lesson.description.isNotEmpty
                      ? lesson.description
                      : 'Read through the course materials carefully to complete this lesson task.',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onCompleted();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lesson marked as completed! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Mark Lesson Completed ✓',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
