import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabmaster/services/local_database_service.dart';

void setupTestEnv() {
  // Initialize FFI for SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});
}

Future<void> clearDatabase() async {
  final dbService = LocalDatabaseService();
  // Ensure the DB is initialized
  await dbService.database; 
  // Clear all tables
  await dbService.clearAll();
}
