<p align="center">
  <img src="./assets/logo.png" width="200px" align="center" alt="Dartonic logo" />
  <h1 align="center">Dartonic</h1>
  <p align="center">
  <a href="https://github.com/evandersondev/dartonic">🍷 Dartonic Github</a>
  <br/>
    A database query builder inspired by <a href="https://drizzledb.com">Drizzle</a>. It allows you to connect to various databases (SQLite, PostgreSQL, MySQL) and perform database operations using a fluent API.
  </p>
</p>

<br/>

---

<br/>

### Support 💖

If you find Dartonic useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the package and make it even better!

<br/>

## Table of Contents

- [Getting Started](#getting-started)
- [Installation](#installation)
- [Connecting to a Database](#connecting-to-a-database)
- [Defining Tables](#defining-tables)
  - [SQLite Example](#sqlite-example)
  - [PostgreSQL Example](#postgresql-example)
  - [MySQL Example](#mysql-example)
- [Working with Relationships](#working-with-relationships)
- [Querying the Database](#querying-the-database)
  - [Simple Queries](#simple-queries)
  - [Complex Queries](#complex-queries)
- [Supported Methods & Examples](#supported-methods--examples)
  - [SELECT](#select)
  - [INSERT](#insert-with-returning)
  - [UPDATE](#update-with-returning)
  - [DELETE](#delete-with-returning)
  - [Join Queries](#join-queries)
  - [Filter Conditions](#filter-conditions)
- [Limitations & Unsupported Types](#limitations--unsupported-types)
- [Contributing](#contributing)
- [License](#license)

<br/>

---

<br/>

## Getting Started

Dartonic is designed to simplify your database interactions in Dart. With its fluent query API, you can build complex queries effortlessly. ✨

<br/>

---

## Installation

Add Dartonic to your `pubspec.yaml`:

```yaml
dependencies:
  dartonic: ^0.0.5
```

<br/>

Then run:

```bash
dart pub get
```

<br/>

Or run:

```bash
dart pub get add dartonic
```

<br/>

---

<br/>

## Connecting to a Database

Dartonic supports multiple databases through connection URIs:

- **SQLite (in memory):**

  ```dart
  final dartonic = Dartonic("sqlite::memory:");
  ```

<br/>

- **SQLite (from file):**

  ```dart
  final dartonic = Dartonic("sqlite:database/database.db");
  ```

<br/>

- **PostgreSQL:**

  ```dart
  final dartonic = Dartonic("postgres://username:password@localhost:5432/database");
  ```

<br/>

- **MySQL:**

  ```dart
  final dartonic = Dartonic("mysql://user:userpassword@localhost:3306/mydb");
  ```

<br/>

Synchronize your tables:

```dart
void main() async {
  final dartonic = Dartonic("sqlite::memory:", [usersTable, ordersTable]);
  await dartonic.sync(); // Synchronize tables
}
```

<br/>

Get instance Dartonic in anywhere in your project:

```dart
final db = dartonic.instance;
```

> 🚨 **Note:** Dartonic uses a singleton pattern – all instances refer to the same connection.

<br/>

---

<br/>

## Defining Tables

Dartonic is inspired by Drizzle and allows you to define table schemas conveniently. Below is an example of creating a SQLite table with custom column definitions.

<br/>

### SQLite Example

> **Note:** Some modifiers or functions may differ on SQLite. Check the SQLite documentation for supported default functions.

```dart
import 'package:dartonic/dartonic.dart';
import 'package:dartonic/columns.dart';

final usersTable = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text().notNull(),
  'age': integer(),
  'email': text().notNull().unique(),
  'created_at': timestamp().notNull().defaultNow(),
  'updated_at': timestamp().notNull().defaultNow(),
});

final ordersTable = sqliteTable('orders', {
  'id': integer().primaryKey(autoIncrement: true),
  'user_id': integer(columnName: 'user_id'),
  'total': integer(),
});
```

<br/>

### PostgreSQL Example

> **Note:** Some modifiers or functions may differ on PostgreSQL. Check the PostgreSQL documentation for supported default functions.

```dart
final usersTable = pgTable('users', {
  'id': serial().generatedAlwaysAsIdentity(),
  'name': varchar(length: 100).notNull(),
  'age': integer(),
});
```

<br/>

### MySQL Example

> **Note:** Auto increment is defined differently on MySQL. Ensure your `primaryKey()` method is correctly implemented for MySQL.

```dart
final usersTable = mysqlTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': varchar(length: 100).notNull(),
});
```

<br/>

---

<br/>

## Working with Relationships

Dartonic allows you to define relationships between tables. This makes it easier to perform related queries using JOINs. Relationships are defined through helper methods (for example, a `relations` function) which let you map the associations.

Here’s an example on how to define one-to-one and one-to-many relationships:

<br/>

```dart
// Defining the base tables.
final usersTable = sqliteTable('users', {
  'id': integer().primaryKey(autoIncrement: true),
  'name': text().notNull(),
  'email': text().notNull().unique(),
});

final profileTable = sqliteTable('profile_info', {
  'id': integer().primaryKey(),
  'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
  'bio': text(),
});

final postsTable = sqliteTable('posts', {
  'id': integer().primaryKey(autoIncrement: true),
  'user_id': integer(columnName: 'user_id').references(() => 'users.id'),
  'content': text(),
});

// Defining relationships.
// For one-to-one relationship: each user has one profileInfo.
final usersRelations = relations(
  usersTable,
  (builder) => {
    'profileInfo': builder.one(
      'profile_info',
      fields: ['users.id'],
      references: ['profile_info.user_id'],
    ),
  },
);

// For one-to-many relationship: each user can have multiple posts.
final postsRelations = relations(
  usersTable,
  (builder) => {
    'posts': builder.many(
      'posts',
      fields: ['users.id'],
      references: ['posts.user_id'],
    ),
  },
);

// Now you can initialize Dartonic with the main tables and include relationship meta-information.
final dartonic = Dartonic("sqlite://database.db", [
  usersTable,
  profileTable,
  postsTable,
  usersRelations,
  postsRelations,
]);
```

<br/>

Once the relationships are defined, you can perform JOIN queries with ease:

<br/>

```dart
// Example JOIN query: Get users with their profile bio.
final query = db
    .select({
      'userName': 'users.name',
      'userEmail': 'users.email',
      'bio': 'profile_info.bio',
    })
    .from('users')
    .innerJoin('profile_info', eq("users.id", "profile_info.user_id"));

print(query.toSql());
final result = await query;
print(result);
```

<br/>

---

<br/>

## Querying the Database

After synchronizing the tables using `sync()`, you can build and execute queries using the fluent API provided by Dartonic.

<br/>

### Simple Queries

- **SELECT all columns:**

  ```dart
  final users = await db.select().from('users');
  print(users);
  ```

- **SELECT specific columns using a map:**

  Here, the key represents the alias (renamed column) and the value represents the actual column.

  ```dart
  final result = await db.select({
    'fieldId': 'users.id',
    'fieldName': 'users.name',
  }).from('users');
  print(result);
  ```

<br/>

### Complex Queries

You can chain multiple methods to build complex queries with joins, filters, ordering, and pagination.

```dart
final complexQuery = db
    .select({
      'userName': 'users.name',
      'orderTotal': 'orders.total'
    })
    .from('users')
    .innerJoin('orders', eq("users.id", "orders.user_id"))
    .where(gt("orders.total", 100))
    .orderBy("users.name")
    .limit(10)
    .offset(0);

print(complexQuery.toSql());
final result = await complexQuery;
print(result);
```

<br/>

---

<br/>

## Supported Methods & Examples

Below are some examples demonstrating all available methods within Dartonic's query builder.

<br/>

### SELECT

Select columns by specifying a map:

```dart
final users = await db
    .select({
      'name': 'users.fullname',
      'age': 'users.birthday'
    })
    .from('users');
print(users);
```

<br/>

### INSERT

Insert only or insert a record and return the full record as well as partial (only id):

```dart
// Insert only
await db
    .insert('users')
    .values({
      'name': "Dan",
      'age': 28
    });

// Insert with returning
final insertedUser = await db
    .insert('users')
    .values({
      'name': "Dan",
      'age': 28
      })
      .returning();

print("Inserted with full RETURNING:");
print(insertedUser);

// Insert and return only id
final insertedPartial = await db
    .insert('users')
    .values({
      'name': "Partial Dan",
      'age': 30
    })
    .returning(['id']);

print("Inserted with partial RETURNING {'id': 1}");
print(insertedPartial);
```

<br/>

### UPDATE

Update only or update a record and return the updated information:

```dart
// Update only
 await db
    .update('users')
    .set({'name': "Daniel", 'age': 29})
    .where(eq("users.id", 1));

// Update with returning
final updatedUser = await db
    .update('users')
    .set({'name': "Daniel", 'age': 29})
    .where(eq("users.id", 1))
    .returning();

print("Updated with full RETURNING:");
print(updatedUser);
```

<br/>

### DELETE

Delete only or delete a record and get the deleted row's data:

```dart
// Delete only
await db
    .delete('users')
    .where(eq("users.id", 3))
    .returning();

// Delete with returning
final deletedUser = await db
    .delete('users')
    .where(eq("users.id", 3))
    .returning();

print("Deleted with full RETURNING:");
print(deletedUser);
```

<br/>

### Join Queries

Perform various types of JOINs:

```dart
// INNER JOIN example: users and orders
final joinQuery = db
    .select({
      'userName': 'users.name',
      'orderTotal': 'orders.total'
    })
    .from('users')
    .innerJoin('orders', eq("users.id", "orders.user_id"))
    .where(gt("orders.total", 100));

print("SQL INNER JOIN with filter:");
print(joinQuery.toSql());

final joinResult = await joinQuery;
print(joinResult);
```

<br/>

### Filter Conditions

You can use a variety of filter methods:

```dart
// Equality filter (eq)
final eqQuery = db.select().from("users").where(eq("users.age", 30));

print("SQL eq:");
print(eqQuery.toSql());
print(await eqQuery);

// Greater-than filter (gt)
final gtQuery = db.select().from("users").where(gt("users.age", 25));

print("SQL gt:");
print(gtQuery.toSql());
print(await gtQuery);

// In array filter
final inArrayQuery = db.select().from("users").where(inArray("users.age", [25, 35]));

print("SQL inArray:");
print(inArrayQuery.toSql());
print(await inArrayQuery);

// Between filter
final betweenQuery = db.select().from("users").where(between("users.age", 26, 34));

print("SQL between:");
print(betweenQuery.toSql());
print(await betweenQuery);

// Composite filter with AND
final andQuery = db.select().from("users").where(
  and([gt("users.age", 25), lt("users.age", 35)])
);

print("SQL and:");
print(andQuery.toSql());
print(await andQuery);

// Composite filter with OR
final orQuery = db.select().from("users").where(
  or([lt("users.age", 25), gt("users.age", 35)])
);

print("SQL or:");
print(orQuery.toSql());
print(await orQuery);
```

<br/>

---

<br/>

## Limitations & Unsupported Types

- **SQLite Restrictions:**

  - Some advanced SQL features like `ILIKE` are not natively supported by SQLite. Although Dartonic generates the SQL, not all features will run as expected on SQLite.

  - Ensure you are using SQLite version 3.35.0 or newer if you plan to use the `RETURNING` clause.

- **Other Databases:**

  - PostgreSQL fully supports the majority of features such as `RETURNING`, `JOIN`s, and advanced filters.

  - MySQL support might vary; confirm your MySQL version supports specific SQL clauses used by Dartonic.

<br/>

---

<br/>

## Contributing

Contributions are very welcome! If you find bugs, have suggestions, or want to contribute new features, please submit an [issue](https://github.com/yourusername/dartonic/issues) or a pull request.

---

## License

🍷 Dartonic is released under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

Made with ❤️ for Dart/Flutter developers! 🎯
