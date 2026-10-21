import 'commands.dart';

/// Deterministic local parser: suggestions, never silent task creation.
/// No network calls or generative-AI claims.
List<TaskInput> suggestTasks(String raw, DateTime now) {
  final pieces = raw
      .replaceAll(RegExp(r'\s+(?:also|plus)\s+', caseSensitive: false), ';')
      .split(RegExp(r'[;\n]+|(?<=[.!?])\s+(?=[A-Z])'));
  final proposals = <TaskInput>[];
  for (final piece in pieces) {
    final cleaned = piece
        .trim()
        .replaceFirst(RegExp(r'^[•\-\d.)\s]+'), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    if (cleaned.isEmpty) continue;
    try {
      proposals.add(parseTaskInput(cleaned, now));
    } on FormatException {
      continue;
    }
    if (proposals.length >= 20) break;
  }
  return proposals;
}
