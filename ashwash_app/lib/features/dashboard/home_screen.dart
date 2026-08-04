import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../mood/mood_tracking_screen.dart';
import '../knowledge_hub/knowledge_hub_screen.dart';
import '../courses/courses_screen.dart';
import '../courses/presentation/screens/course_catalog_screen.dart';
import '../appointments/specialist_list_screen.dart';
import '../profile/report_screen.dart';
import '../mind_games/mind_games_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMoodIndex = 1; // Default 😊

  final List<String> _moodEmojis = ['😃', '😊', '😐', '😔', '😢'];

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 36,
              width: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              isBn ? 'আশ্বাস' : 'Ashwash',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 28),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // How are you feeling today? (Mood Widget)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'আজ আপনার অনুভূতি কেমন?' : 'How are you feeling today?',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_moodEmojis.length, (index) {
                      final isSelected = _selectedMoodIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedMoodIndex = index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isBn ? 'মুড রেকর্ড করা হয়েছে!' : 'Mood logged successfully!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)]
                                : [],
                          ),
                          child: Text(
                            _moodEmojis[index],
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isBn ? 'আপনার অগ্রগতি' : 'Your Progress', style: AppTypography.heading2(context)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                  },
                  child: Text(isBn ? 'সব দেখুন' : 'View All', style: const TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  // Circular Ring 43%
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      fit: StackFit.expand,
                      children: const [
                        CircularProgressIndicator(
                          value: 0.43,
                          strokeWidth: 8,
                          backgroundColor: Color(0xFFEDE9FE),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        Center(
                          child: Text(
                            '43%',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('5', isBn ? 'সেশন' : 'Sessions', Icons.calendar_today_rounded),
                        _buildStatItem('1', isBn ? 'কাজ সম্পন্ন' : 'Tasks Done', Icons.check_circle_outline),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Grid (All 4 items have distinct realistic image logos!)
            Text(isBn ? 'দ্রুত পদক্ষেপ' : 'Quick Actions', style: AppTypography.heading2(context)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildQuickActionCard(
                  context,
                  isBn ? 'জ্ঞান কেন্দ্র' : 'Knowledge Hub',
                  Icons.menu_book_rounded,
                  AppColors.primary,
                  'assets/images/knowledge_hub_icon.jpg',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KnowledgeHubScreen())),
                ),
                _buildQuickActionCard(
                  context,
                  isBn ? 'মাইন্ড গেমস' : 'Mind Games',
                  Icons.sports_esports_rounded,
                  Colors.indigo,
                  'assets/images/mind_games_icon.jpg',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MindGamesHubScreen())),
                ),
                _buildQuickActionCard(
                  context,
                  isBn ? 'কোর্সসমূহ' : 'Browse Courses',
                  Icons.school_rounded,
                  AppColors.secondary,
                  'assets/images/courses_browse_icon.jpg',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCatalogScreen(categoryId: 'ALL', categoryTitle: 'Browse Courses'))),
                ),
                _buildQuickActionCard(
                  context,
                  isBn ? 'সেশন বুক করুন' : 'Book Session',
                  Icons.event_available_rounded,
                  Colors.pink,
                  'assets/images/specialist_consult_icon.jpg',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistListScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My Courses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isBn ? 'আমার কোর্সসমূহ' : 'My Courses', style: AppTypography.heading2(context)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseCatalogScreen(categoryId: 'ALL', categoryTitle: 'Browse Courses'))),
                  child: Text(isBn ? 'সব দেখুন' : 'View All', style: const TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCourseProgressCard(context, 'Postpartum Depression Recovery Program', '2/17 lessons', 0.25, '25%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData fallbackIcon,
    Color color,
    String? imagePath,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: color, size: 28),
                ),
              )
            else
              Icon(fallbackIcon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseProgressCard(BuildContext context, String title, String subtitle, double progress, String pctText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(pctText, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
