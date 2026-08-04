import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language_provider.dart';
import '../dashboard/home_screen.dart';
import '../community/community_screen.dart';
import '../chat/ai_chat_placeholder_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CommunityScreen(),
    AIChatPlaceholderScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = Provider.of<AppLanguageProvider>(context).isBangla;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: isBn ? 'হোম' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.groups_rounded),
              label: isBn ? 'কমিউনিটি' : 'Community',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: isBn ? 'চ্যাট' : 'Chat',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              label: isBn ? 'প্রোফাইল' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
