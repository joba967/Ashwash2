import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/category_model.dart';

import '../../../navigation/presentation/screens/main_navigation_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = '1';
  }

  Future<void> _saveAndProceed(String categoryId) async {
    setState(() => _selectedCategoryId = categoryId);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setCategoryPreference(categoryId);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  String _getCategoryTitle(String id) {
    try {
      final categories = ApiService().getMockCategories();
      final cat = categories.firstWhere((c) => c.id.toString() == id);
      return cat.titleEn;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBn = langProvider.isBangla;
    final categories = ApiService().getMockCategories();

    return Scaffold(

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Screen Header (Matching Figma Page 2 Screen 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    isBn ? 'আপনার বিভাগ নির্বাচন করুন' : 'Select Your Category',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBn
                        ? 'ব্যক্তিগত কোর্স এবং সহায়তা পেতে আপনার বিভাগ বেছে নিন'
                        : 'Choose your category to get personalized courses and support',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Card Scrollable List (Matching Figma Cards)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final catIdStr = cat.id.toString();
                  final isSelected = _selectedCategoryId == catIdStr;

                  IconData iconData = Icons.favorite_rounded;
                  if (cat.icon == 'mother') iconData = Icons.family_restroom_rounded;
                  if (cat.icon == 'people') iconData = Icons.people_alt_rounded;
                  if (cat.icon == 'briefcase') iconData = Icons.work_rounded;
                  if (cat.icon == 'school') iconData = Icons.school_rounded;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cat.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cat.color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _saveAndProceed(catIdStr),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Circular Icon Background
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  iconData,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Title and Subtitle Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isBn ? cat.titleBn : cat.titleEn,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isBn ? cat.descriptionBn : cat.descriptionEn,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                },
              ),
            ),

            // Bottom "Skip for now" Pill Button (Matching Figma Page 2 Screen 6)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isBn ? 'এখনই নয়' : 'Skip for now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
