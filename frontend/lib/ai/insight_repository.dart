import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'verdict.dart';

/// Persistent record of an LLM verdict for a setup.
class InsightRecord {
  final String id; // setup fingerprint
  final String symbol;
  final String timeframe;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Verdict verdict;
  final bool dismissed;
  final bool pinned;

  const InsightRecord({
    required this.id,
    required this.symbol,
    required this.timeframe,
    required this.createdAt,
    required this.expiresAt,
    required this.verdict,
    required this.dismissed,
    required this.pinned,
  });
}

/// SQLite-backed store for insight records. Desktop-only (uses `sqflite_ffi`).
///
/// Why SQLite: filtered queries (per-ticker, by date), concurrent-safe writes
/// from the dispatcher, trivial schema migrations. JSON-on-disk breaks down
/// quickly once we have thousands of records.
class InsightRepository {
  static const _schemaVersion = 1;
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'halo_insights.db');
    _db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE insights (
              id TEXT PRIMARY KEY,
              symbol TEXT NOT NULL,
              timeframe TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              expires_at INTEGER,
              verdict_json TEXT NOT NULL,
              dismissed INTEGER NOT NULL DEFAULT 0,
              pinned INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_insights_symbol_created ON insights(symbol, created_at DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_insights_active ON insights(dismissed, created_at DESC)',
          );
        },
      ),
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('InsightRepository.init() must be called before use');
    }
    return db;
  }

  Future<void> upsert({
    required String fingerprint,
    required String symbol,
    required String timeframe,
    required Verdict verdict,
    DateTime? expiresAt,
  }) async {
    await _database.insert(
      'insights',
      {
        'id': fingerprint,
        'symbol': symbol,
        'timeframe': timeframe,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'expires_at': expiresAt?.millisecondsSinceEpoch,
        'verdict_json': jsonEncode(verdict.toJson()),
        'dismissed': 0,
        'pinned': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InsightRecord>> recent({int limit = 100}) async {
    final rows = await _database.query(
      'insights',
      where: 'dismissed = 0',
      orderBy: 'pinned DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToRecord).toList();
  }

  Future<void> dismiss(String id) async {
    await _database.update('insights', {'dismissed': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> pin(String id, {bool pinned = true}) async {
    await _database.update('insights', {'pinned': pinned ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> pruneExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.delete(
      'insights',
      where: 'pinned = 0 AND expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [now],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  InsightRecord _rowToRecord(Map<String, Object?> row) {
    final json = jsonDecode(row['verdict_json']! as String) as Map<String, dynamic>;
    return InsightRecord(
      id: row['id']! as String,
      symbol: row['symbol']! as String,
      timeframe: row['timeframe']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((row['created_at']! as num).toInt()),
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((row['expires_at']! as num).toInt()),
      verdict: Verdict.fromJson(json),
      dismissed: ((row['dismissed'] as int?) ?? 0) == 1,
      pinned: ((row['pinned'] as int?) ?? 0) == 1,
    );
  }
}

// Platform note: on Windows/Linux/macOS desktop, sqflite_common_ffi uses
// native sqlite3. The sqfliteFfiInit() call inside `init()` is the only
// initialization needed.
