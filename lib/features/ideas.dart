import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models.dart';
import '../core/state.dart';
import 'neo.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});
  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with AutomaticKeepAliveClientMixin<IdeasScreen> {
  @override
  bool get wantKeepAlive => true;
  String query = '';
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final snapshot = ref.watch(appProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load Ideas: $e')),
      data: (data) {
        final notes = data.notes
            .where((n) => n.text.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return ScreenBody(
          children: [
            const Headline(
              'IDEAS & OTHER CHAOS ✦',
              'A home for thoughts that don’t belong anywhere else.',
            ),
            NeoButton(
              label: '+ CATCH A THOUGHT',
              icon: Icons.edit_note_rounded,
              onPressed: () => showIdeaEditor(context),
            ),
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Find an idea...',
              ),
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              const EmptyState(
                'Your next big idea starts here.',
                'Tap + to jot something down. Notes save automatically.',
                icon: Icons.lightbulb_outline,
              ),
            ...notes.map(
              (idea) => NeoCard(
                onTap: () => showIdeaEditor(context, note: idea),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (idea.pinned)
                          const Icon(Icons.push_pin_rounded, size: 18),
                        const Spacer(),
                        IconButton(
                          tooltip: idea.pinned ? 'Unpin idea' : 'Pin idea',
                          onPressed: () => ref
                              .read(appProvider.notifier)
                              .change(
                                (db) => db.saveIdea(
                                  id: idea.id,
                                  text: idea.text,
                                  pinned: !idea.pinned,
                                ),
                              ),
                          icon: Icon(
                            idea.pinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete idea',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await confirmDelete(context, 'idea')) return;
                            await ref
                                .read(appProvider.notifier)
                                .change((db) => db.deleteIdea(idea.id));
                          },
                        ),
                      ],
                    ),
                    Text(
                      idea.text,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Tap to edit · ${idea.pinned ? 'Pinned' : 'Autosaved'}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showIdeaEditor(BuildContext context, {IdeaNote? note}) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _IdeaEditor(note: note),
    );

class _IdeaEditor extends ConsumerStatefulWidget {
  const _IdeaEditor({this.note});
  final IdeaNote? note;
  @override
  ConsumerState<_IdeaEditor> createState() => _IdeaEditorState();
}

class _IdeaEditorState extends ConsumerState<_IdeaEditor> {
  late final input = TextEditingController(text: widget.note?.text ?? '');
  late bool pinned = widget.note?.pinned ?? false;
  int? id;
  Timer? debounce;
  bool writing = false, dirty = false;
  @override
  void initState() {
    super.initState();
    id = widget.note?.id;
    input.addListener(onChanged);
  }

  void onChanged() {
    dirty = true;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 550), save);
  }

  Future<void> save() async {
    if (writing || !dirty || input.text.trim().isEmpty) return;
    writing = true;
    dirty = false;
    try {
      id = await ref
          .read(appProvider.notifier)
          .change(
            (db) => db.saveIdea(id: id, text: input.text, pinned: pinned),
          );
    } catch (e) {
      dirty = true;
      if (mounted) toast(context, 'Could not save idea: $e');
    } finally {
      writing = false;
      if (dirty && mounted) {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 500), save);
      }
    }
  }

  Future<void> close() async {
    debounce?.cancel();
    // Wait for an in-progress auto-save, then flush latest text before closing.
    while (writing) {
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }
    if (input.text.trim().isNotEmpty) {
      dirty = true;
      await save();
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> makeTask() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    final title = text.split('\n').first.trim();
    if (title.isEmpty || !mounted) return;
    try {
      await ref
          .read(appProvider.notifier)
          .change(
            (db) => db.saveTask(
              title: title.length > 180 ? title.substring(0, 180) : title,
            ),
          );
      if (mounted) toast(context, 'Added idea as a task ✓');
    } catch (e) {
      if (mounted) toast(context, 'Could not add task: $e');
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    input.removeListener(onChanged);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      18,
      8,
      18,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'IDEA PAD ✦',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: pinned ? 'Unpin' : 'Pin',
                icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                onPressed: () {
                  setState(() => pinned = !pinned);
                  dirty = true;
                  debounce?.cancel();
                  debounce = Timer(const Duration(milliseconds: 350), save);
                },
              ),
            ],
          ),
          const Text('Autosaved on this device. No account needed.'),
          const SizedBox(height: 12),
          TextField(
            controller: input,
            maxLength: 10000,
            minLines: 6,
            maxLines: 12,
            autofocus: true,
            decoration: const InputDecoration(
              hintText:
                  'A random thought, a brilliant idea, or something to remember...',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: makeTask,
            icon: const Icon(Icons.add_task),
            label: const Text('TURN INTO A TASK'),
          ),
          FilledButton.icon(
            onPressed: close,
            icon: const Icon(Icons.check),
            label: const Text('DONE'),
          ),
        ],
      ),
    ),
  );
}
