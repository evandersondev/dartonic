import 'dart:convert';
import 'dart:io';

import 'package:dartonic_core/dartonic_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// Starts the Dartonic Studio HTTP backend.
///
/// Exposes:
/// - `GET  /tables`         — list all registered table names
/// - `GET  /tables/:name`   — describe columns for a table
/// - `POST /query`          — execute a raw SQL SELECT and return results
///
/// Example:
/// ```dart
/// import 'package:dartonic_studio/dartonic_studio.dart';
///
/// await startStudio(db, port: 4444);
/// // Visit http://localhost:4444/tables
/// ```
Future<HttpServer> startStudio(
  DartonicDb db, {
  int port = 4444,
  String host = 'localhost',
}) async {
  final router = Router()
    ..get('/tables', (Request req) => _listTables(req, db))
    ..get('/tables/<name>', (Request req, String name) => _describeTable(req, db, name))
    ..post('/query', (Request req) => _runQuery(req, db));

  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, host, port);
  stdout.writeln('Dartonic Studio running at http://$host:$port');
  return server;
}

Response _json(Object data, {int status = 200}) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );

Response _listTables(Request req, DartonicDb db) {
  final tables = db.schemas.map((t) => t.tableName).toList();
  return _json({'tables': tables});
}

Response _describeTable(Request req, DartonicDb db, String name) {
  final schema = db.schema(name);
  if (schema == null) {
    return _json({'error': 'Table "$name" not found'}, status: 404);
  }

  final columns = {
    for (final col in schema.columns)
      col.column: {
        'type': col.sqlType,
        'nullable': col.nullable,
        'modifiers': col.modifiers,
      },
  };

  return _json({'table': name, 'columns': columns});
}

Future<Response> _runQuery(Request req, DartonicDb db) async {
  try {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final sql = body['sql'] as String?;

    if (sql == null || sql.trim().isEmpty) {
      return _json({'error': 'Missing "sql" field'}, status: 400);
    }

    // Only allow SELECT for safety
    if (!sql.trim().toUpperCase().startsWith('SELECT')) {
      return _json({'error': 'Only SELECT queries are allowed'}, status: 403);
    }

    final rows = await db.rawQuery(sql);
    return _json({'rows': rows, 'count': rows.length});
  } catch (e) {
    return _json({'error': e.toString()}, status: 500);
  }
}

Middleware _corsMiddleware() {
  return (Handler handler) => (Request req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final response = await handler(req);
        return response.change(headers: _corsHeaders);
      };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};
