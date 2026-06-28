import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase.isGuestDatabase', () {
    test('default-constructed database is the guest DB', () {
      final db = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.isGuestDatabase, isTrue);
    });

    test('database with a non-guest name is the per-user DB', () {
      final db = AppDatabase(
        executor: NativeDatabase.memory(),
        name: 'enjoy_player_user-42',
      );
      addTearDown(db.close);
      expect(db.isGuestDatabase, isFalse);
    });

    test('explicit guest name still reports guest', () {
      final db = AppDatabase(
        executor: NativeDatabase.memory(),
        name: AppDatabase.guestDatabaseName,
      );
      addTearDown(db.close);
      expect(db.isGuestDatabase, isTrue);
    });
  });
}
