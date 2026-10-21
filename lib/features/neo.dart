import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/appearance.dart';
import '../core/state.dart';

Color themeColor(BuildContext context, int index) {
  final c = look(context);
  return switch (index % 5) {
    0 => c.primary,
    1 => c.secondary,
    2 => c.tertiary,
    3 => Color.lerp(c.primary, c.secondary, .48)!,
    _ => Color.lerp(c.secondary, c.tertiary, .52)!,
  };
}

/// Cards feel physical: a small downward press and a hard offset shadow.
class NeoCard extends ConsumerStatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  ConsumerState<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends ConsumerState<NeoCard> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final c = look(context),
        dark = Theme.of(context).brightness == Brightness.dark;
    final noMotion =
        ref.watch(reduceMotionProvider).value ??
        false || MediaQuery.disableAnimationsOf(context);
    final color = widget.color ?? c.paper;
    final bright = color.computeLuminance() > .42;
    return AnimatedContainer(
      duration: noMotion ? Duration.zero : const Duration(milliseconds: 135),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(pressed ? 3 : 0, pressed ? 3 : 0, 0),
      margin: const EdgeInsets.only(bottom: 14, right: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: c.outline, width: 2.4),
        boxShadow: [
          BoxShadow(
            color: dark ? c.primary.withValues(alpha: .45) : Colors.black,
            offset: Offset(pressed ? 1 : 4, pressed ? 1 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => pressed = true),
          onTapCancel: widget.onTap == null
              ? null
              : () => setState(() => pressed = false),
          onTapUp: widget.onTap == null
              ? null
              : (_) => setState(() => pressed = false),
          onTap: widget.onTap == null
              ? null
              : () {
                  if (ref.read(hapticsProvider).value ?? true)
                    HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          borderRadius: BorderRadius.circular(16),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.color == null
                  ? c.ink
                  : (bright ? Colors.black : Colors.white),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class NeoButton extends StatelessWidget {
  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = look(context);
    final bg = color ?? c.secondary;
    final ink = bg.computeLuminance() > .42 ? Colors.black : Colors.white;
    return NeoCard(
      color: bg,
      padding: EdgeInsets.zero,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: ink, size: 19),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(17, 18, 17, 22),
    children: children,
  );
}

class Headline extends StatelessWidget {
  const Headline(this.heading, this.subtitle, {super.key});
  final String heading, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: Theme.of(context).textTheme.headlineLarge),
        Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.subtitle, {
    super.key,
    this.icon = Icons.inbox_outlined,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => NeoCard(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String what) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $what?'),
        content: const Text(
          'This permanently deletes the selected item and its history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
