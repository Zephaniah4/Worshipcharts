import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class LocalDatabase extends GeneratedDatabase {
  LocalDatabase({bool inMemory = false}) : super(_openConnection(inMemory: inMemory));

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const <TableInfo<Table, Object?>>[];

  @override
  int get schemaVersion => 1;

  Future<void> init() async {
    await customStatement('''
      create table if not exists songs_local (
        id text primary key,
        payload text not null,
        updated_at text not null
      );
    ''');
    await customStatement('''
      create table if not exists setlists_local (
        id text primary key,
        payload text not null,
        updated_at text not null
      );
    ''');
    await customStatement('''
      create table if not exists sync_queue_local (
        id text primary key,
        payload text not null,
        created_at text not null
      );
    ''');
  }

  Future<void> upsertSongRow({required String id, required String payload, required String updatedAt}) async {
    await customStatement(
      'insert into songs_local (id, payload, updated_at) values (?, ?, ?) '
      'on conflict(id) do update set payload = excluded.payload, updated_at = excluded.updated_at',
      <Object>[id, payload, updatedAt],
    );
  }

  Future<void> upsertSetlistRow({required String id, required String payload, required String updatedAt}) async {
    await customStatement(
      'insert into setlists_local (id, payload, updated_at) values (?, ?, ?) '
      'on conflict(id) do update set payload = excluded.payload, updated_at = excluded.updated_at',
      <Object>[id, payload, updatedAt],
    );
  }

  Future<List<String>> loadSongPayloads() async {
    final List<QueryRow> rows = await customSelect('select payload from songs_local order by updated_at desc').get();
    return rows.map((QueryRow row) => row.read<String>('payload')).toList();
  }

  Future<List<String>> loadSetlistPayloads() async {
    final List<QueryRow> rows = await customSelect('select payload from setlists_local order by updated_at desc').get();
    return rows.map((QueryRow row) => row.read<String>('payload')).toList();
  }

  Future<void> upsertSyncQueueRow({required String id, required String payload, required String createdAt}) async {
    await customStatement(
      'insert into sync_queue_local (id, payload, created_at) values (?, ?, ?) '
      'on conflict(id) do update set payload = excluded.payload, created_at = excluded.created_at',
      <Object>[id, payload, createdAt],
    );
  }

  Future<List<String>> loadSyncQueuePayloads() async {
    final List<QueryRow> rows = await customSelect('select payload from sync_queue_local order by created_at asc').get();
    return rows.map((QueryRow row) => row.read<String>('payload')).toList();
  }

  Future<void> deleteSyncQueueRows(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final String placeholders = List<String>.filled(ids.length, '?').join(', ');
    await customStatement('delete from sync_queue_local where id in ($placeholders)', ids);
  }
}

QueryExecutor _openConnection({required bool inMemory}) {
  if (inMemory) {
    return NativeDatabase.memory();
  }

  final File file = File('${Directory.systemTemp.path}${Platform.pathSeparator}worship_app_local.sqlite');
  return NativeDatabase(file);
}
