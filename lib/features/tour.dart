import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'neo.dart';
import '../core/appearance.dart';

class KaryaTourScreen extends StatefulWidget {
  const KaryaTourScreen({super.key});
  @override
  State<KaryaTourScreen> createState() => _KaryaTourScreenState();
}

class _KaryaTourScreenState extends State<KaryaTourScreen> {
  int index = 0;
  final controller = PageController();
  static const content = <({IconData icon, String title, String body})>[
    (
      icon: Icons.waving_hand_outlined,
      title: 'HEY, WELCOME TO KĀRYA ✦',
      body:
          'Less Organising. More Doing. Everything you need, nothing you don’t.',
    ),
    (
      icon: Icons.folder_copy_outlined,
      title: 'START WITH SUBJECTS',
      body:
          'Create folders for classes, projects or anything on your mind. They’re front and center on Home.',
    ),
    (
      icon: Icons.add_task_outlined,
      title: 'ADD TASKS IN SECONDS',
      body:
          'Tap + to capture a task. Add a deadline or subject only when you want to.',
    ),
    (
      icon: Icons.auto_awesome_outlined,
      title: 'BUILD SMALL HABITS',
      body:
          'Check habits off every day they’re scheduled. Watch real progress grow.',
    ),
    (
      icon: Icons.lightbulb_outline,
      title: 'KEEP YOUR IDEAS',
      body: 'Jot down a passing thought, pin it, or turn it into a task.',
    ),
    (
      icon: Icons.palette_outlined,
      title: 'MAKE IT FEEL LIKE YOU',
      body:
          'Choose one of five personalities with light or true-black dark mode. Swipe to move between tabs.',
    ),
    (
      icon: Icons.bubble_chart_outlined,
      title: 'DUMP YOUR BRAIN',
      body:
          'Brain Dump can turn messy text into task suggestions for you to review. No cloud, no ads, no fake AI.',
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void next() {
    if (index == content.length - 1) {
      context.pop();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = look(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('THE 30-SECOND TOUR'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Skip')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (i) => setState(() => index = i),
                children: [
                  for (final item in content)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: NeoCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 36,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.icon, size: 72, color: c.primary),
                                const SizedBox(height: 25),
                                Text(
                                  item.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  item.body,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < content.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 190),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 7,
                          width: i == index ? 24 : 7,
                          decoration: BoxDecoration(
                            color: i == index ? c.primary : c.muted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: next,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          index == content.length - 1 ? 'LET’S GO ✦' : 'NEXT',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
