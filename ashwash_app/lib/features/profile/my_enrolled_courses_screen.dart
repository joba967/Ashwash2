import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../data/models/course_model.dart';
import '../courses/course_detail_screen.dart';
import '../courses/courses_screen.dart';

class MyEnrolledCoursesScreen extends StatelessWidget {
  const MyEnrolledCoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final isBn = langProvider.isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final enrolledCourses = dashboardProvider.enrolledCourses;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'আমার এনরোল করা কোর্সসমূহ' : 'My Enrolled Courses',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: enrolledCourses.isEmpty
          ? _buildEmptyState(context, isBn, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: enrolledCourses.length,
              itemBuilder: (context, index) {
                final cMap = enrolledCourses[index];
                return _buildEnrolledCourseCard(context, cMap, isBn, isDark);
              },
            ),
    );
  }

  Widget _buildEnrolledCourseCard(BuildContext context, Map<String, dynamic> cMap, bool isBn, bool isDark) {
    final String title = cMap['title'] ?? 'Mental Health Recovery Program';
    final String description = cMap['description'] ?? 'Comprehensive course covering daily resilience & mental wellbeing.';
    final int completedLessons = cMap['completed_lessons'] ?? 2;
    final int totalLessons = cMap['total_lessons'] ?? 17;
    final int progressPercent = cMap['progress_percentage'] ?? 25;

    final dummyCourseModel = CourseModel(
      id: cMap['id'] ?? 1,
      titleEn: title,
      titleBn: 'মানসিক সুস্থতা প্রোগ্রাম',
      descriptionEn: description,
      descriptionBn: 'দৈনন্দিন মানসিক সুস্থতা অর্জনের পথনির্দেশনা।',
      duration: '6 Weeks',
      price: 0.0,
      isFree: true,
      rating: 4.9,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header Banner Thumbnail
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.school_rounded,
                size: 54,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Description
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),

          // Course Progress Details Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? '$totalLessons টির মধ্যে $completedLessons টি লেসন সম্পন্ন' : '$completedLessons of $totalLessons Lessons Completed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CourseDetailScreen(course: dummyCourseModel)),
                );
              },
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
              label: Text(
                isBn ? 'কোর্স চালিয়ে যান' : 'Continue Course',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isBn, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 64,
                color: Color(0xFFA855F7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isBn ? 'আপনি এখনো কোনো কোর্সে এনরোল করেননি' : 'No Enrolled Courses Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'মানসিক স্বাস্থ্য ও সুস্থতার জন্য সকল কোর্স ব্রাউজ করুন এবং আপনার কোর্স শুরু করুন।'
                  : 'Explore our mental wellness programs and enroll in courses designed by expert psychologists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoursesScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                isBn ? 'সকল কোর্স ব্রাউজ করুন' : 'Browse All Courses',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
