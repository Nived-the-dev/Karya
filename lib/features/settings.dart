import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/appearance.dart';
import '../core/notifications.dart';
import '../core/state.dart';
import 'neo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notifications = false,
      defaultTaskReminders = false,
      defaultHabitReminders = false;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted)
        setState(() {
          notifications = prefs.getBool('notifications') ?? false;
          defaultTaskReminders =
              prefs.getBool('default_task_reminders') ?? false;
          defaultHabitReminders =
              prefs.getBool('default_habit_reminders') ?? false;
        });
    });
  }

  Future<void> toggle(bool enable) async {
    if (enable) {
      final allowed = await Reminders.instance.requestPermission();
      if (!allowed) {
        if (mounted)
          toast(context, 'Notifications are disabled in Android settings.');
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enable);
    if (mounted) setState(() => notifications = enable);
    try {
      await Reminders.instance.sync(await ref.read(dbProvider).snapshot());
    } catch (e) {
      if (mounted) toast(context, 'Could not schedule reminders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeProvider).value ?? 'system';
    final style = ref.watch(personalityProvider).value ?? 0;
    final haptics = ref.watch(hapticsProvider).value ?? true;
    final motion = ref.watch(reduceMotionProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS ✦')),
      body: ScreenBody(
        children: [
          const Headline(
            'MAKE IT YOURS.',
            'One app. Five personalities. Ten palettes.',
          ),
          Text('YOUR THEME', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (ctx, size) => Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                for (var i = 0; i < themeNames.length; i++)
                  SizedBox(
                    width: (size.maxWidth - 10) / 2,
                    child: _ThemeTile(
                      index: i,
                      selected: i == style,
                      onTap: () => ref
                          .read(personalityProvider.notifier)
                          .setPersonality(i),
                    ),
                  ),
              ],
            ),
          ),
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BRIGHTNESS',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  spacing: 5,
                  children: [
                    for (final m in ['light', 'dark', 'system'])
                      ChoiceChip(
                        label: Text(
                          m == 'system'
                              ? 'Follow system'
                              : m[0].toUpperCase() + m.substring(1),
                        ),
                        selected: mode == m,
                        onSelected: (_) =>
                            ref.read(themeProvider.notifier).setTheme(m),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'All dark themes use a pure-black background (#000000).',
                ),
              ],
            ),
          ),
          NeoCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Subtle vibrations'),
                  subtitle: const Text(
                    'A small tap response for navigation and cards.',
                  ),
                  value: haptics,
                  onChanged: (v) =>
                      ref.read(hapticsProvider.notifier).setEnabled(v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce animations'),
                  subtitle: const Text(
                    'Shorter or no transitions, including tab changes.',
                  ),
                  value: motion,
                  onChanged: (v) =>
                      ref.read(reduceMotionProvider.notifier).setEnabled(v),
                ),
              ],
            ),
          ),
          NeoCard(
            onTap: () => context.push('/tour'),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.explore_outlined),
              title: Text('Replay the guided tour'),
              subtitle: Text('A quick tour through all Kārya features.'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          NeoCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Assignment & habit reminders',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Optional local Android notifications.'),
              value: notifications,
              onChanged: toggle,
            ),
          ),
          NeoCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('New tasks: remind 1 hour before due'),
                  value: defaultTaskReminders,
                  onChanged: (v) async {
                    await (await SharedPreferences.getInstance()).setBool(
                      'default_task_reminders',
                      v,
                    );
                    if (mounted) setState(() => defaultTaskReminders = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('New habits: default 6 PM reminder'),
                  value: defaultHabitReminders,
                  onChanged: (v) async {
                    await (await SharedPreferences.getInstance()).setBool(
                      'default_habit_reminders',
                      v,
                    );
                    if (mounted) setState(() => defaultHabitReminders = v);
                  },
                ),
              ],
            ),
          ),
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE STORY BEHIND THE CHAOS',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'I am a very very messy person, like really messy. I thought why not fix this shit.\n\nSo I vibe coded Kārya.\n\nI hate ADS man I really hate em so it’s offline and no ads (yay).\n\nHope it helps!\n\n— Nived Chandrasudan',
                  style: TextStyle(height: 1.45),
                ),
                const SizedBox(height: 14),
                const Text('Kārya (कार्य) 2.1 · Less Organising. More Doing.'),
                const SizedBox(height: 6),
                const Text(
                  'No advertisements, subscriptions or mandatory accounts. Your task and idea content stays on your device in this version.',
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub project'),
                  subtitle: const Text('github.com/Nived-the-dev/Karya'),
                  onTap: () => launchProjectUrl(
                    'https://github.com/Nived-the-dev/Karya',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('LinkedIn · Nived'),
                  onTap: () => launchProjectUrl(
                    'https://www.linkedin.com/in/nived-chandrasudan-8a454b434/',
                  ),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Privacy Policy'),
                      content: const SingleChildScrollView(
                        child: Text(privacyText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Kārya',
                    applicationVersion: '2.1',
                  ),
                  child: const Text('Open-source licenses'),
                ),
              ],
            ),
          ),
          NeoCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete all app data'),
              subtitle: const Text(
                'Delete tasks, folders, ideas, habit records and preferences.',
              ),
              onTap: () async {
                final answer = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear everything?'),
                    content: const Text(
                      'This cannot be undone. Every locally stored task, idea and habit will be deleted.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete all'),
                      ),
                    ],
                  ),
                );
                if (answer != true) return;
                await ref
                    .read(appProvider.notifier)
                    .change((db) => db.clearAll());
                await (await SharedPreferences.getInstance()).clear();
                await Reminders.instance.sync(
                  await ref.read(dbProvider).snapshot(),
                );
                ref.invalidate(themeProvider);
                ref.invalidate(personalityProvider);
                ref.invalidate(hapticsProvider);
                ref.invalidate(reduceMotionProvider);
                if (mounted) {
                  setState(() {
                    notifications = false;
                    defaultTaskReminders = false;
                    defaultHabitReminders = false;
                  });
                  toast(context, 'Everything local has been deleted.');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> launchProjectUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted)
      toast(context, 'Could not open the link.');
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = paletteFor(index, isDark);
    return NeoCard(
      onTap: onTap,
      color: c.paper,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: c.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.outline),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.tertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  themeNames[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: c.ink,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: c.ink,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const privacyText = '''Kārya 2.1 Privacy Policy (draft · October 2026)

Kārya stores tasks, subtasks, subjects, habits, ideas, and completion history in an on-device SQLite database. Theme, haptics, and reminder preferences are stored locally. No account, advertising, analytics, cloud sync or remote AI service is used. Brain Dump is a deterministic offline text parser and does not transmit what you type.

Notification permission is requested only if you choose reminders, which continue to work without a Kārya server. Android cloud backup and device-transfer backup are disabled in the app manifest. External links to GitHub and LinkedIn are only opened if you tap them, and those websites have their own policies.

Delete locally stored data through Settings > Delete all app data or uninstall the app. The publisher must provide a real support contact and public HTTPS privacy-policy URL before Google Play release.''';
