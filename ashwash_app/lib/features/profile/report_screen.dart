import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isGenerating = false;

  void _downloadReport(BuildContext context, bool isBn) async {
    setState(() => _isGenerating = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBn ? 'স্বয়ংক্রিয় ক্লিনিক্যাল PDF রিপোর্ট প্রস্তুত হচ্ছে...' : 'Generating automatic clinical PDF report...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isGenerating = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Text(isBn ? 'রিপোর্ট ডাউনলোড সফল' : 'Report Downloaded'),
          ],
        ),
        content: Text(
          isBn
              ? 'আপনার মানসিক স্বাস্থ্য রিপোর্ট "Ashwash_Clinical_Report.pdf" ফাইলে ডাউনলোড সম্পন্ন হয়েছে।'
              : 'Your mental health report has been generated and saved to "Ashwash_Clinical_Report.pdf".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বন্ধ করুন' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _viewFullReportModal(context, isBn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isBn ? 'রিপোর্ট দেখুন' : 'View Report', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewFullReportModal(BuildContext context, bool isBn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBn ? 'ক্লিনিক্যাল রিপোর্ট ভিউ' : 'Clinical Health Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBn ? 'রোগীর নাম: আশ্বাসের সদস্য' : 'Patient Name: Ashwash Member',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isBn ? 'তারিখ: ১ আগস্ট, ২০২৬ | আইডি: #ASH-9821' : 'Date: Aug 1, 2026 | ID: #ASH-9821',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Breakdown
                    Text(
                      isBn ? 'মানসিক সূচক বিশ্লেষণ' : 'Mental Wellness Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildReportMetricRow('Mood Stability Index', '88% (Excellent)', Colors.green, isDark),
                    _buildReportMetricRow('Anxiety Level Score', '12 / 63 (Low Risk)', Colors.blue, isDark),
                    _buildReportMetricRow('Postpartum Recovery Progress', '25% Completed', AppColors.primary, isDark),
                    _buildReportMetricRow('Specialist Consultations', '5 Sessions Completed', Colors.orange, isDark),

                    const SizedBox(height: 20),
                    Text(
                      isBn ? 'বিশেষজ্ঞের পরামর্শ ও নোট' : 'Specialist Clinical Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isBn
                            ? 'রোগীর পোস্টপার্টাম রিকভারি অগ্রগতি অত্যন্ত সন্তোষজনক। মুড ডায়াল এবং গাইডেড মেডিটেশন নিয়মিত চর্চা করায় উদ্বেগ উল্লেখযোগ্যভাবে হ্রাস পেয়েছে।'
                            : 'Patient shows strong emotional stability and steady reduction in postpartum anxiety. Recommended to continue Module 2 self-care exercises.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportMetricRow(String title, String val, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isBn ? 'মানসিক স্বাস্থ্য রিপোর্ট' : 'Mental Health Report',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue Header Banner with Automatic Generation & Download Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isBn ? 'আপনার যাত্রার স্বয়ংক্রিয় ক্লিনিক্যাল রিপোর্ট' : 'Auto-Generated Clinical Health Record',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBn ? 'কোর্স প্রোগ্রেস, মুড ট্র্যাক ও সেশন তথ্য থেকে তৈরি' : 'Compiled automatically from mood logs & sessions',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isGenerating ? null : () => _downloadReport(context, isBn),
                          icon: _isGenerating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            isBn ? 'ডাউনলোড' : 'Download PDF',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _viewFullReportModal(context, isBn),
                          icon: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
                          label: Text(
                            isBn ? 'রিপোর্ট দেখুন' : 'View Report',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overview Section
            Text(
              isBn ? 'সংক্ষিপ্ত সারমর্ম' : 'Overview',
              style: AppTypography.heading2(context),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildOverviewTile('1', isBn ? 'কোর্সে এনরোলড' : 'Courses Enrolled', Icons.menu_book_rounded, isDark),
                _buildOverviewTile('2/17', isBn ? 'পাঠ সম্পন্ন' : 'Lessons Completed', Icons.trending_up_rounded, isDark),
                _buildOverviewTile('5', isBn ? 'সেশনে অংশগ্রহণ' : 'Sessions Attended', Icons.calendar_today_rounded, isDark),
                _buildOverviewTile('450', isBn ? 'পয়েন্ট অর্জিত' : 'Points Earned', Icons.military_tech_rounded, isDark),
              ],
            ),
            const SizedBox(height: 24),

            // Doctor Feedback Section
            Text(
              isBn ? 'বিশেষজ্ঞের মতামত' : 'Specialist Notes',
              style: AppTypography.heading2(context),
            ),
            const SizedBox(height: 12),
            _buildDoctorFeedbackCard(
              'Dr. Mekhala Sarkar',
              'July 28, 2026',
              'Great progress in managing postpartum anxiety. Patient shows significant improvement in self-care routine.',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildDoctorFeedbackCard(
              'Dr. Nusrat Jahan',
              'August 1, 2026',
              'Patient is actively participating in guided meditation and completing reflection journal assignments.',
              isDark,
            ),
            const SizedBox(height: 24),

            // Treatment Timeline
            Text(
              isBn ? 'চিকিৎসার টাইমলাইন' : 'Treatment Timeline',
              style: AppTypography.heading2(context),
            ),
            const SizedBox(height: 12),
            _buildTimelineItem('Aug 1, 2026', 'Completed Postpartum Mood Assessment', isDark),
            _buildTimelineItem('Jul 28, 2026', 'First consultation with Dr. Mekhala Sarkar', isDark),
            _buildTimelineItem('Jul 25, 2026', 'Started Postpartum Depression Recovery Program', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTile(String count, String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.grey.shade800) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorFeedbackCard(String name, String date, String note, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: const Text('D', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (_) => const Icon(Icons.star, color: Colors.amber, size: 16)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
