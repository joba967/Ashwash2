import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../widgets/mood_selector_widget.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/my_courses_list.dart';
import '../../../mood/presentation/screens/progress_details_screen.dart';
import '../../../hub/presentation/screens/knowledge_hub_screen.dart';
import '../../../mind_games/mind_games_hub_screen.dart';
import '../../../courses/presentation/screens/course_catalog_screen.dart';
import '../../../appointments/specialist_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 36,
              width: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'আশ্বাস',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications: 2 new updates available.')),
                  );
                },
              ),
              if (dashboardProvider.hasUnreadNotifications)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => dashboardProvider.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Mood Tracker Sentiment Card
                    const MoodSelectorWidget(),
                    const SizedBox(height: 24),

                    // 2. Your Progress Section
                    ProgressSummaryCard(
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressDetailsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 3. Quick Actions 2x2 Grid
                    QuickActionsGrid(
                      onActionTap: (route) {
                        if (route == 'knowledge_hub') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KnowledgeHubScreen()),
                          );
                        } else if (route == 'mind_game') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MindGamesHubScreen()),
                          );
                        } else if (route == 'browse_courses') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CourseCatalogScreen(
                                categoryId: 'ALL',
                                categoryTitle: 'Browse Courses',
                              ),
                            ),
                          );
                        } else if (route == 'book_session') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SpecialistListScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigating to $route...')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 4. My Courses Section
                    MyCoursesList(
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseCatalogScreen(
                              categoryId: 'POSTPARTUM_DEPRESSION',
                              categoryTitle: 'Postpartum Depression',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
