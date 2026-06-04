// Hide Dartonic's condition helpers that collide with matcher names.
import 'package:dartonic_core/dartonic_core.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

void main() {
  group('BoolColumn', () {
    final c = BoolColumn('active');
    test('encodes to 1/0/null', () {
      expect(c.encode(true), 1);
      expect(c.encode(false), 0);
      expect(c.encode(null), isNull);
    });
    test('decodes from bool/int/string', () {
      expect(c.decode(1), isTrue);
      expect(c.decode(0), isFalse);
      expect(c.decode(true), isTrue);
      expect(c.decode('true'), isTrue);
      expect(c.decode('1'), isTrue);
      expect(c.decode(null), isNull);
    });
  });

  group('DateTimeColumn', () {
    test('string storage round-trips as UTC ISO-8601', () {
      final c = DateTimeColumn('ts');
      final d = DateTime.utc(2024, 1, 2, 3, 4, 5);
      expect(c.encode(d), '2024-01-02T03:04:05.000Z');
      expect(c.decode('2024-01-02T03:04:05.000Z'), d);
    });
    test('epochMs storage round-trips', () {
      final c = DateTimeColumn('ts', storage: DateTimeStorage.epochMs);
      final d = DateTime.utc(2024, 1, 1);
      expect(c.encode(d), d.millisecondsSinceEpoch);
      expect(c.decode(d.millisecondsSinceEpoch), d);
    });
  });

  group('DoubleColumn', () {
    final c = DoubleColumn('amount');
    test('decodes int and comma-decimal strings', () {
      expect(c.decode(2), 2.0);
      expect(c.decode('3,14'), 3.14);
      expect(c.decode('3.14'), 3.14);
    });
  });

  group('JsonColumn', () {
    final c = JsonColumn<Map<String, Object?>>(
      'data',
      decoder: (raw) => (raw as Map).cast<String, Object?>(),
      encoder: (v) => v,
    );
    test('encodes via jsonEncode and decodes via jsonDecode', () {
      expect(c.encode({'a': 1}), '{"a":1}');
      expect(c.decode('{"a":1}'), {'a': 1});
      expect(c.encode(null), isNull);
    });
  });
}
