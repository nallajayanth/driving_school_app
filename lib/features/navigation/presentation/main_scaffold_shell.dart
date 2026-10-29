import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_header.dart';
import '../../authentication/presentation/auth_providers.dart';

/// The root scaffold shell hosting the 4 persistent bottom navigation tabs and top header.
class MainScaffoldShell extends ConsumerStatefulWidget {
  const MainScaffoldShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffoldShell> createState() => _MainScaffoldShellState();
}

class _MainScaffoldShellState extends ConsumerState<MainScaffoldShell> {
  String _currentLanguage = 'DE';

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final activeLanguage =
        userAsync.asData?.value?.preferredLanguage ?? _currentLanguage;

    return Scaffold(
      appBar: AppHeader(
        selectedLanguage: activeLanguage,
        onLanguageChanged: (lang) {
          setState(() {
            _currentLanguage = lang;
          });
          ref.read(currentUserProvider.notifier).changeLanguage(lang);
        },
        onLogout: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Log out'),
              content: const Text(
                'Are you sure you want to log out of your session?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(currentUserProvider.notifier).logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out of session (Mock)'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Log out',
                    style: TextStyle(color: AppColors.logout),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Learning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_turned_in_rounded),
              label: 'Pre-Check',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              activeIcon: Icon(Icons.trending_up_rounded),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
