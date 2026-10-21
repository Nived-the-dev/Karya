import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'models.dart';
import 'notifications.dart';

final dbProvider = Provider<KaryaDatabase>((ref) {
  final db = KaryaDatabase();
  ref.onDispose(db.close);
  return db;
});
final appProvider = AsyncNotifierProvider<AppController, AppData>(
  AppController.new,
);

class AppController extends AsyncNotifier<AppData> {
  @override
  Future<AppData> build() async {
    final data = await ref.read(dbProvider).snapshot();
    try {
      await Reminders.instance.sync(data);
    } catch (_) {
      /* allow app startup without notifications */
    }
    return data;
  }

  Future<T> change<T>(Future<T> Function(KaryaDatabase) operation) async {
    final db = ref.read(dbProvider);
    final result = await operation(db);
    final fresh = await db.snapshot();
    state = AsyncData(fresh);
    try {
      await Reminders.instance.sync(fresh);
    } catch (_) {
      /* data writes must succeed even when reminders are blocked */
    }
    return result;
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(dbProvider).snapshot());
  }
}

final themeProvider = AsyncNotifierProvider<KaryaThemeController, String>(
  KaryaThemeController.new,
);

class KaryaThemeController extends AsyncNotifier<String> {
  @override
  Future<String> build() async =>
      (await SharedPreferences.getInstance()).getString('theme') ?? 'system';
  Future<void> setTheme(String mode) async {
    (await SharedPreferences.getInstance()).setString('theme', mode);
    state = AsyncData(mode);
  }
}

final personalityProvider =
    AsyncNotifierProvider<KaryaPersonalityController, int>(
      KaryaPersonalityController.new,
    );

class KaryaPersonalityController extends AsyncNotifier<int> {
  @override
  Future<int> build() async =>
      ((await SharedPreferences.getInstance()).getInt('personality') ?? 0)
          .clamp(0, 4);
  Future<void> setPersonality(int value) async {
    final selected = value.clamp(0, 4);
    await (await SharedPreferences.getInstance()).setInt(
      'personality',
      selected,
    );
    state = AsyncData(selected);
  }
}

final hapticsProvider = AsyncNotifierProvider<KaryaHapticsController, bool>(
  KaryaHapticsController.new,
);

class KaryaHapticsController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool('haptics') ?? true;
  Future<void> setEnabled(bool value) async {
    await (await SharedPreferences.getInstance()).setBool('haptics', value);
    state = AsyncData(value);
  }
}

final reduceMotionProvider = AsyncNotifierProvider<KaryaMotionController, bool>(
  KaryaMotionController.new,
);

class KaryaMotionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool('reduced_motion') ??
      false;
  Future<void> setEnabled(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(
      'reduced_motion',
      value,
    );
    state = AsyncData(value);
  }
}
