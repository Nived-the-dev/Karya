import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/appearance.dart';
import 'core/state.dart';
import 'core/notifications.dart';
import 'features/screens.dart';
import 'features/ideas.dart';
import 'features/tour.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Reminders.instance.initialize();
  } catch (_) {
    /* App must work without notifications. */
  }
  runApp(const ProviderScope(child: KaryaApp()));
}

/// A shared tab request makes folder-to-task navigation work from Home.
final tabRequest = ValueNotifier<int>(0);
void selectKaryaTab(int index) {
  if (tabRequest.value == index) tabRequest.value = -1;
  tabRequest.value = index;
}

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AppScaffold()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/tour', builder: (_, __) => const KaryaTourScreen()),
  ],
);

class KaryaApp extends ConsumerWidget {
  const KaryaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider).value ?? 'system';
    final style = ref.watch(personalityProvider).value ?? 0;
    return MaterialApp.router(
      title: 'Kārya — कार्य',
      debugShowCheckedModeBanner: false,
      theme: neoTheme(false, style),
      darkTheme: neoTheme(true, style),
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});
  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  late final PageController controller = PageController();
  int page = 0;
  static const labels = ['Home', 'Tasks', 'Habits', 'Ideas', 'Progress'];
  static const icons = [
    Icons.home_rounded,
    Icons.check_box_rounded,
    Icons.auto_awesome_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.bar_chart_rounded,
  ];

  @override
  void initState() {
    super.initState();
    tabRequest.addListener(onRequestedTab);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (!(prefs.getBool('tour_seen') ?? false)) {
        await context.push('/tour');
        await prefs.setBool('tour_seen', true);
      }
    });
  }

  @override
  void dispose() {
    tabRequest.removeListener(onRequestedTab);
    controller.dispose();
    super.dispose();
  }

  void onRequestedTab() {
    if (mounted) selectTab(tabRequest.value);
  }

  void selectTab(int next) {
    if (next < 0 || next >= labels.length) return;
    if (ref.read(hapticsProvider).value ?? true)
      HapticFeedback.selectionClick();
    final reduce =
        ref.read(reduceMotionProvider).value ??
        false || MediaQuery.disableAnimationsOf(context);
    if (reduce)
      controller.jumpToPage(next);
    else
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = look(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KĀRYA ✦',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: c.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Brain Dump & shortcuts',
            icon: const Icon(Icons.bubble_chart_outlined),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: PageView(
        controller: controller,
        onPageChanged: (next) {
          setState(() => page = next);
          if (ref.read(hapticsProvider).value ?? true)
            HapticFeedback.selectionClick();
        },
        children: const [
          HomeScreen(),
          TasksScreen(),
          HabitsScreen(),
          IdeasScreen(),
          ProgressScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 16, 8),
          height: 70,
          decoration: BoxDecoration(
            color: c.paper,
            border: Border.all(color: c.outline, width: 2.3),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? c.primary.withValues(alpha: .55)
                    : Colors.black,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, size) => AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final position =
                    controller.hasClients &&
                        controller.position.hasContentDimensions
                    ? (controller.page ?? page.toDouble())
                    : page.toDouble();
                final unit = size.maxWidth / labels.length;
                return Stack(
                  children: [
                    Positioned(
                      left: position * unit + 5,
                      top: 5,
                      bottom: 5,
                      width: unit - 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.primary.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.27
                                : 0.45,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: InkWell(
                              key: Key('nav_${labels[i].toLowerCase()}'),
                              onTap: () => selectTab(i),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icons[i], size: 23, color: c.ink),
                                  const SizedBox(height: 3),
                                  Text(
                                    labels[i],
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: i == page
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: c.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
