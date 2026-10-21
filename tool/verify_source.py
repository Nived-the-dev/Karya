#!/usr/bin/env python3
"""Offline source, SQLite, Android XML, and artwork smoke checks.

NO Dart compilation or Android runtime testing is performed by this script.
"""
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZipFile
from xml.etree import ElementTree as ET
import re
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[1]
SQL_DART = (ROOT / 'lib/core/database.dart').read_text(encoding='utf-8')


def ddl():
    match = re.search(r'static const schema\s*=\s*<String>\[(.*?)\n\s*\];', SQL_DART, re.S)
    if not match:
        raise AssertionError('Could not locate database SQL schema declarations')
    chunks = re.findall(r"'''(.*?)'''", match.group(1), re.S)
    extra = re.search(r"static const notesSchema = '''(.*?)'''", SQL_DART, re.S)
    if extra: chunks.insert(0, extra.group(1))
    if len(chunks) < 10:
        raise AssertionError('Missing SQL schema statements')
    return chunks


def create(conn):
    conn.execute('PRAGMA foreign_keys=ON')
    for stmt in ddl():
        conn.execute(stmt)


class KaryaSourceTests(unittest.TestCase):
    def test_android_config_is_valid(self):
        manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
        ns = '{http://schemas.android.com/apk/res/android}'
        perms = [p.attrib.get(ns + 'name') for p in manifest.findall('uses-permission')]
        self.assertNotIn('android.permission.INTERNET', perms)
        self.assertIn('android.permission.POST_NOTIFICATIONS', perms)
        self.assertIn('android.permission.RECEIVE_BOOT_COMPLETED', perms)
        app = manifest.find('application')
        self.assertEqual(app.attrib.get(ns + 'allowBackup'), 'false')
        self.assertIsNotNone(app.find('activity'))
        rules = ET.parse(ROOT / 'android/app/src/main/res/xml/data_extraction_rules.xml').getroot()
        self.assertIsNotNone(rules.find('cloud-backup/exclude'))
        self.assertIsNotNone(rules.find('device-transfer/exclude'))
        gradle = (ROOT / 'android/app/build.gradle.kts').read_text()
        self.assertIn('targetSdk = 36', gradle)
        self.assertIn('isCoreLibraryDesugaringEnabled = true', gradle)

    def test_sql_constraints_and_foreign_keys(self):
        db = sqlite3.connect(':memory:')
        create(db)
        db.execute('INSERT INTO subjects(name,color,icon) VALUES (?,?,?)', ('Maths',0,0))
        with self.assertRaises(sqlite3.IntegrityError):
            db.execute('INSERT INTO subjects(name,color,icon) VALUES (?,?,?)', ('maths',1,1))
        db.execute("INSERT INTO tasks(title,priority,created_at,subject_id) VALUES ('Revise','high','2026-10-21',1)")
        db.execute("INSERT INTO subtasks(task_id,title) VALUES (1,'Notes')")
        db.execute('DELETE FROM subjects WHERE id=1')
        self.assertIsNone(db.execute('SELECT subject_id FROM tasks').fetchone()[0])
        db.execute('DELETE FROM tasks WHERE id=1')
        self.assertEqual(db.execute('SELECT COUNT(*) FROM subtasks').fetchone()[0], 0)
        with self.assertRaises(sqlite3.IntegrityError):
            db.execute("INSERT INTO tasks(title,priority,created_at) VALUES ('Bad','invalid','2026-10-21')")
        db.close()

    def test_habit_log_uniqueness_and_parent_delete(self):
        db = sqlite3.connect(':memory:')
        create(db)
        db.execute("INSERT INTO habits(name,created_day) VALUES ('Read','2026-10-21')")
        db.execute("INSERT INTO habit_schedules VALUES (1,'2026-10-21',127)")
        db.execute("INSERT INTO habit_logs VALUES (1,'2026-10-21')")
        with self.assertRaises(sqlite3.IntegrityError):
            db.execute("INSERT INTO habit_logs VALUES (1,'2026-10-21')")
        db.execute('DELETE FROM habits WHERE id=1')
        for table in ('habit_logs','habit_schedules'):
            self.assertEqual(db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0], 0)
        db.close()

    def test_database_is_persistent_file(self):
        with TemporaryDirectory() as folder:
            database = Path(folder) / 'karya.sqlite'
            with sqlite3.connect(database) as db:
                create(db)
                db.execute("INSERT INTO subjects(name) VALUES ('Science')")
            with sqlite3.connect(database) as db:
                self.assertEqual(db.execute('SELECT name FROM subjects').fetchone()[0], 'Science')

    def test_no_user_facing_json_export(self):
        for path in (ROOT/'lib').rglob('*.dart'):
            source=path.read_text()
            self.assertNotIn('/export',source)
            self.assertNotIn('Export JSON',source)

    def test_assets_are_valid_png_dimensions(self):
        # The first 24 bytes contain PNG signature and width/height; no Pillow required.
        for name, dims in [('play_icon_512.png', (512,512)), ('feature_graphic_1024x500.png', (1024,500))]:
            raw = (ROOT / 'store_assets' / name).read_bytes()[:24]
            self.assertEqual(raw[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual((int.from_bytes(raw[16:20],'big'),int.from_bytes(raw[20:24],'big')), dims)

    def test_bundled_required_docs_and_no_keystore(self):
        for name in ['README.md','PROJECT_STATUS.md','TEST_RESULTS.md','FEATURES.md',
                     'PLAY_STORE_LISTING.md','RELEASE_CHECKLIST.md','PRIVACY_POLICY.html',
                     'GOOGLE_PLAY_PUBLISHING_GUIDE.md']:
            self.assertTrue((ROOT/name).is_file(), name)
        self.assertFalse(list(ROOT.rglob('*.jks')))
        self.assertFalse(list(ROOT.rglob('key.properties')))

    def test_command_coverage(self):
        combined = ((ROOT/'lib/core/commands.dart').read_text() +
                    (ROOT/'lib/features/chat.dart').read_text())
        for command in ['/addtask','/viewtasks','/markdone','/undo','/today','/upcoming',
                        '/overdue','/search','/priority','/edit','/delete','/addhabit',
                        '/viewhabits','/donehabit','/stats','/help']:
            self.assertIn(command, combined)

if __name__ == '__main__':
    unittest.main(verbosity=2)
