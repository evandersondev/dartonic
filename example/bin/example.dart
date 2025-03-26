import 'package:darto/darto.dart';
import 'package:dartonic/dartonic.dart';

void main() async {
  final app = Darto();

  final events = sqliteTable('events', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text(),
    'date': timestamp(),
  });

  // Definindo a tabela de attendees (participantes)
  final attendees = sqliteTable('attendees', {
    'id': integer().primaryKey(autoIncrement: true),
    'name': text(),
    'eventId': integer().references(() => 'events.id'),
  });

  // Relacionamento entre eventos e participantes (one-to-many)
  final eventsRelations = relations(
    events,
    (builder) => {
      'attendees': builder.many(
        'attendees',
        fields: ['id'],
        references: ['eventId'],
      ),
    },
  );

  // Relacionamento entre participantes e eventos (many-to-one)
  final attendeesRelations = relations(
    attendees,
    (builder) => {
      'event': builder.one('events', fields: ['eventId'], references: ['id']),
    },
  );

  final dartonic = Dartonic("sqlite:database/dartonic.db", [
    events,
    attendees,
    eventsRelations,
    attendeesRelations,
  ]);

  final db = await dartonic.sync();

  await db.insert("events").values({
    'name': 'Tech Conference',
    'date': DateTime.now().toIso8601String(),
  });

  // Inserindo participantes para o evento com id 1 (assumindo que o evento inserido tem id = 1)
  await db.insert("attendees").values({'name': 'John Doe', 'eventId': 1});
  await db.insert("attendees").values({'name': 'Jane Doe', 'eventId': 1});

  // Selecionando todos os eventos com seus participantes
  final eventsWithAttendees = await db
      .select()
      .from("events")
      .innerJoin("attendees", eq("events.id", "attendees.eventId"));
  print("Eventos com participantes:");
  print(eventsWithAttendees);

  // Selecionando todos os participantes com seus eventos
  final attendeesWithEvents = await db
      .select()
      .from("attendees")
      .innerJoin("events", eq("attendees.eventId", "events.id"));
  print("Participantes com eventos:");
  print(attendeesWithEvents);

  // await db.insert('roles').values({'name': 'user'});
  // await db.insert('roles').values({'name': 'admin'});

  // Criar mais relacionamentos
  // await db.insert('user_roles').values({
  //   'user_id': 2, // John Doe
  //   'role_id': 2, // role user
  // });

  // await db.insert('user_roles').values({
  //   'user_id': 2, // Jane Doe
  //   'role_id': 1, // role admin
  // });

  // Primeiro vamos garantir que o count está funcionando corretamente
  // Primeiro, confirmamos que temos 2 roles no sistema
  // final totalRoles = await db
  //     .select()
  //     .from('users')
  //     .where(like('users.name', '%John%'));
  // print('Total de Roles: $totalRoles');

  // Query para buscar usuários e suas roles
  // final usersWithRoles = await db
  //     .select({
  //       'name': 'users.name',
  //       'total_roles': count(
  //         'user_roles.role_id',
  //         distinct: true,
  //       ), // sql('COUNT(DISTINCT user_roles.role_id)'),
  //     })
  //     .from('users')
  //     .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'))
  //     .groupBy(['users.id', 'users.name']);
  // print('Usuários e suas roles: $usersWithRoles');

  // // Query para buscar apenas usuários que têm TODAS as roles
  // final usersWithAllRoles = await db
  //     .select({
  //       'name': 'users.name',
  //       'total_roles': 'COUNT(DISTINCT user_roles.role_id)',
  //     })
  //     .from('users')
  //     .innerJoin('user_roles', eq('users.id', 'user_roles.user_id'))
  //     .groupBy(['users.id', 'users.name'])
  //     .having(eq('COUNT(DISTINCT user_roles.role_id)', totalRoles[0]['total']));
  // print('Usuários com todas as roles: $usersWithAllRoles');

  // final userUpdate =
  //     await db
  //         .update('users')
  //         .set({'name': 'John Doe Updated'})
  //         .where(eq('id', 1))
  //         .returning();
  // print(userUpdate);

  // await db.delete('users').where(eq('users.id', 1));

  app.listen(3000, () => print('Server is running on port 3000'));
}
