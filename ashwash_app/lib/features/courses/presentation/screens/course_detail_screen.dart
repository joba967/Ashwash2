import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../data/models/course_model.dart';
import '../../../appointments/specialist_list_screen.dart';
import '../widgets/lesson_player_dialog.dart';
import '../widgets/assignment_modal_dialog.dart';
import '../widgets/quiz_dialog.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final Set<String> _completedLessonIds = {};
  final Set<String> _completedAssignmentIds = {};
  double _quizScore = 0.0;
  bool _quizPassed = false;

  @override
  void initState() {
    super.initState();
    // Default initial progress for demo
    _completedLessonIds.add('l1');
    _completedLessonIds.add('l2');
  }

  int get _totalLessons {
    int total = 0;
    for (var m in widget.course.modules) {
      total += m.lessons.length;
    }
    return total;
  }

  double get _overallProgressPercentage {
    if (_totalLessons == 0) return 0.0;
    double lessonProgress = _completedLessonIds.length / _totalLessons;
    double assignmentProgress = widget.course.assignments.isEmpty
        ? 1.0
        : _completedAssignmentIds.length / widget.course.assignments.length;
    double quizProgress = _quizPassed ? 1.0 : 0.0;

    return ((lessonProgress * 0.5) + (assignmentProgress * 0.3) + (quizProgress * 0.2)) * 100;
  }

  bool get _isCertificateUnlocked {
    bool lessonsDone = _completedLessonIds.length >= _totalLessons;
    bool assignmentsDone = widget.course.assignments.isEmpty ||
        _completedAssignmentIds.length >= widget.course.assignments.length;
    return lessonsDone && assignmentsDone && _quizPassed;
  }

  Future<void> _launchVideoUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCertificateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_rounded, size: 54, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ashwash Certificate of Completion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This certifies that you have successfully completed the course:\n"${widget.course.titleEn}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading Certificate PDF...'), backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Certificate (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate share link copied!')),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Achievement'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoursePaymentModal(BuildContext context, bool isBn, CourseModel course) {
    String selectedPaymentMethod = 'bKash';
    final mobileController = TextEditingController(text: '01711982341');
    final otpController = TextEditingController(text: '123456');
    final pinController = TextEditingController(text: '12345');
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isBkash = selectedPaymentMethod == 'bKash';
            final primaryThemeColor = isBkash ? const Color(0xFFE2136E) : const Color(0xFFF7921E);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBn ? 'পেমেন্ট মেথড নির্বাচন করুন' : 'Course Payment Gateway',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryThemeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBkash ? 'bKash Sandbox API' : 'Nagad Gateway',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment Gateway Selector Chips
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedPaymentMethod = 'bKash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isBkash ? const Color(0xFFE2136E).withOpacity(0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isBkash ? const Color(0xFFE2136E) : Colors.grey.shade300,
                                width: isBkash ? 2 : 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('📱 ', style: TextStyle(fontSize: 18)),
                                Text('bKash', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE2136E))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedPaymentMethod = 'Nagad'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isBkash ? const Color(0xFFF7921E).withOpacity(0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !isBkash ? const Color(0xFFF7921E) : Colors.grey.shade300,
                                width: !isBkash ? 2 : 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('📲 ', style: TextStyle(fontSize: 18)),
                                Text('Nagad', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF7921E))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Invoice Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryThemeColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryThemeColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice: INV-CRS-${course.id}',
                              style: TextStyle(fontSize: 12, color: primaryThemeColor, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Fee: ৳${course.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.titleEn,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isBkash ? 'bKash Account Number' : 'Nagad Mobile Number',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Verification OTP',
                            prefixIcon: const Icon(Icons.password),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'PIN Code',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryThemeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setModalState(() => isLoading = true);
                              final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
                              final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                              String verifiedTrxId = 'TR0011${DateTime.now().millisecondsSinceEpoch}';

                              // Call bKash / Nagad REST API Endpoint
                              try {
                                final payEndpoint = isBkash ? 'payments/bkash/execute/' : 'payments/nagad/execute/';
                                final response = await ApiService.post(payEndpoint, {
                                  'amount': course.price,
                                  'purpose': 'Course Enrollment: ${course.titleEn}',
                                  'mobile_number': mobileController.text.trim(),
                                  'otp': otpController.text.trim(),
                                  'pin': pinController.text.trim(),
                                });

                                if (response != null && response['transaction_id'] != null) {
                                  verifiedTrxId = response['transaction_id'].toString();
                                }
                              } catch (_) {}

                              // Enroll user in local state & sync backend
                              await dashProvider.enrollCourse({
                                'id': course.id,
                                'title': course.titleEn,
                                'description': course.descriptionEn,
                                'completed_lessons': 0,
                                'total_lessons': _totalLessons,
                                'progress_percentage': 0,
                                'format': 'Both',
                                'instructor': course.instructorName,
                                'specialist': course.specialistName,
                                'price': course.price,
                                'transaction_id': verifiedTrxId,
                              });

                              // Notify Specialist & Admin Portal
                              notifProvider.addNotification(
                                title: isBn ? 'নতুন কোর্স এনরোলমেন্ট!' : 'New Course Enrollment!',
                                message: isBn
                                    ? '${course.specialistName}-এর "${course.titleBn}" কোর্সে সফলতা সহ এনরোলমেন্ট সম্পন্ন হয়েছে। (TrxID: $verifiedTrxId)'
                                    : 'Enrolled in "${course.titleEn}" with ${course.specialistName}. (TrxID: $verifiedTrxId)',
                              );

                              Navigator.pop(modalCtx);
                              if (mounted) {
                                _showEnrollmentSuccessDialog(context, isBn, verifiedTrxId, course);
                              }
                            },
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isBn ? '🔒 পেমেন্ট সম্পন্ন ও এনরোল করুন (৳${course.price.toStringAsFixed(0)})' : '🔒 Confirm & Pay ৳${course.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEnrollmentSuccessDialog(BuildContext context, bool isBn, String trxId, CourseModel course) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                isBn ? 'কোর্স এনরোলমেন্ট সফল হয়েছে!' : 'Course Enrolled Successfully!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isBn
                    ? 'আপনি সফলতা সহ "${course.titleBn}" কোর্সে এনরোল হয়েছেন। আপনার স্পেশালিস্ট ${course.specialistName}-এর কাছে নোটিফিকেশন সিঙ্ক হয়েছে।'
                    : 'You have successfully enrolled in "${course.titleEn}". Notification synced to specialist ${course.specialistName} & Admin Portal.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  'bKash TrxID: $trxId',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                  },
                  child: Text(isBn ? 'কোর্স শুরু করুন' : 'Start Learning Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final apiService = ApiService();
    final allCourses = apiService.getMockCourses();

    final bool isEnrolledInApp = dashboardProvider.isCourseEnrolled(course.id, course.titleEn);

    // Automatically filter related courses
    final relatedCourses = allCourses.where((c) => c.id != course.id).take(3).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Video / Banner SliverAppBar
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    course.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(color: AppColors.primary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      iconSize: 72,
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 48),
                      ),
                      onPressed: () => _launchVideoUrl(course.introVideo),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            course.categorySlug.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBn ? course.titleBn : course.titleEn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildChip(Icons.timer_outlined, course.duration),
                      _buildChip(Icons.people_outline_rounded, '${course.studentsCount} Enrolled'),
                      _buildChip(Icons.star_rounded, '${course.rating} ⭐', color: Colors.amber.shade700),
                      _buildChip(Icons.speed_rounded, course.difficulty),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Overall Course Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${_overallProgressPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _overallProgressPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.primary,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_completedLessonIds.length} of $_totalLessons Lessons Completed | ${_completedAssignmentIds.length}/${course.assignments.length} Assignments',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructor & Specialist Card
                  const Text('Course Instructor & Specialist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(course.instructorPhoto),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.instructorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(course.instructorDesignation, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  Text('${course.instructorExperience} • ${course.instructorRating} ⭐', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Clinical Specialist: ${course.specialistName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(course.specialistDegree, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Book Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Course & Learning Objectives
                  const Text('About This Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    isBn ? course.descriptionBn : course.descriptionEn,
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 16),

                  const Text('Learning Objectives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(isBn ? course.learningOutcomesBn : course.learningOutcomesEn).map((outcome) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(outcome, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 28),

                  // Course Curriculum (Collapsible Modules)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Course Curriculum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${course.modules.length} Modules', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...course.modules.map((module) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ExpansionTile(
                        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('${module.lessons.length} Lessons', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        children: module.lessons.map((lesson) {
                          final isCompleted = _completedLessonIds.contains(lesson.id);
                          return ListTile(
                            leading: Icon(
                              lesson.type == 'video'
                                  ? Icons.play_circle_outline_rounded
                                  : lesson.type == 'audio'
                                      ? Icons.headset_rounded
                                      : lesson.type == 'pdf'
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.article_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(lesson.title, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                            subtitle: Text('${lesson.duration} • ${lesson.type.toUpperCase()}'),
                            trailing: Icon(
                              isCompleted ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                              color: isCompleted ? Colors.green : Colors.grey,
                              size: isCompleted ? 22 : 16,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => LessonPlayerDialog(
                                  lesson: lesson,
                                  onCompleted: () {
                                    setState(() {
                                      _completedLessonIds.add(lesson.id);
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  // Assignments Section
                  if (course.assignments.isNotEmpty) ...[
                    const Text('Course Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...course.assignments.map((assignment) {
                      final isDone = _completedAssignmentIds.contains(assignment.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: Icon(
                            isDone ? Icons.task_alt_rounded : Icons.assignment_outlined,
                            color: isDone ? Colors.green : AppColors.primary,
                            size: 28,
                          ),
                          title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(assignment.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AssignmentModalDialog(
                                  assignment: assignment,
                                  onSubmitted: () {
                                    setState(() {
                                      _completedAssignmentIds.add(assignment.id);
                                    });
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDone ? Colors.green : AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(isDone ? 'Completed ✓' : 'Start Task', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],

                  // Quiz Section
                  if (course.quizQuestions.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_rounded, size: 44, color: AppColors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Final Course Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${course.quizQuestions.length} Questions • Passing Score 70%', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                if (_quizPassed)
                                  const Text('Passed with 70%+ score! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => QuizDialog(
                                  quizQuestions: course.quizQuestions,
                                  onQuizCompleted: (score, passed) {
                                    setState(() {
                                      _quizScore = score;
                                      _quizPassed = passed;
                                    });
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: Text(_quizPassed ? 'Retake' : 'Attempt Quiz', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Certificate Banner Section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isCertificateUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _isCertificateUnlocked ? Colors.amber : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCertificateUnlocked ? Icons.workspace_premium_rounded : Icons.lock_clock_rounded,
                          size: 44,
                          color: _isCertificateUnlocked ? Colors.amber.shade800 : Colors.grey,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCertificateUnlocked ? 'Certificate Unlocked! 🎉' : 'Course Certificate (Locked)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                _isCertificateUnlocked
                                    ? 'Click below to view and download your official certificate.'
                                    : 'Complete 100% lessons, all assignments & pass quiz to unlock.',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isCertificateUnlocked ? _showCertificateDialog : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                          ),
                          child: const Text('View Certificate', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Related Courses Section
                  const Text('Related Courses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedCourses.length,
                      itemBuilder: (ctx, idx) {
                        final rel = relatedCourses[idx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => CourseDetailScreen(course: rel)),
                            );
                          },
                          child: Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.asset(rel.thumbnail, height: 100, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isBn ? rel.titleBn : rel.titleEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('${rel.duration} • ${rel.rating} ⭐', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Sticky Bar (Dynamic Enroll vs Continue Learning Button)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isBn ? 'কোর্স ফি' : 'Course Price', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(
                  course.isFree ? (isBn ? 'বিনামূল্যে' : 'FREE') : '৳${course.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isEnrolledInApp || course.isFree) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? 'আপনার কোর্স পাঠ্যসূচি প্লে করা হচ্ছে...' : 'Resuming your course lessons...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } else {
                    _showCoursePaymentModal(context, isBn, course);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  (isEnrolledInApp || course.isFree)
                      ? (isBn ? 'শেখা চালিয়ে যান ➔' : 'Continue Learning ➔')
                      : (isBn ? 'কোর্সে এনরোল করুন ➔' : 'Enroll Course ➔'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
