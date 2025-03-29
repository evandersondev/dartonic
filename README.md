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

If you find Dartonic useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the framework and make it even better!

<br/>

## Table of Contents

- [Getting Started](#getting-started)
- [Installation](#installation)
- [Connecting to a Database](#connecting-to-a-database)
- [Defining Tables](#defining-tables)
  - [SQLite Example](#sqlite-example)
  - [PostgreSQL Example (Not Supported Yet)](#postgresql-example-not-supported-yet)
  - [MySQL Example](#mysql-example)
- [Index and Constraints Updates](#index-and-constraints-updates)
- [Working with Relationships](#working-with-relationships)
- [Querying the Database](#querying-the-database)
  - [Simple Queries](#simple-queries)
  - [Complex Queries](#complex-queries)
- [Supported Methods & Examples](#supported-methods--examples)
  - [SELECT](#select)
  - [INSERT](#insert)
  - [UPDATE](#update)
  - [DELETE](#delete)
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
  dartonic: ^0.0.3
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
  // Not Supported yet
  final dartonic = Dartonic("postgres://username:password@localhost:5432/database");
  ```

<br/>

- **MySQL:**

  ```dart
  // Not Supported yet
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

Get the Dartonic instance anywhere in your project:

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
```

**Generated SQL Example:**

```sql
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  age INTEGER,
  email TEXT NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

<br/>

### PostgreSQL Example (Not Supported Yet)

> **Note:** Some modifiers or functions may differ on PostgreSQL. Check the PostgreSQL documentation for supported default functions.

```dart
final usersTable = pgTable('users', {
  'id': serial().generatedAlwaysAsIdentity(),
  'name': varchar(length: 100).notNull(),
  'age': integer(),
});
```

**Generated SQL Example:**

```sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(100) NOT NULL,
  age INTEGER
);
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

**Generated SQL Example:**

```sql
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL
);
```

<br/>

---

<br/>

## Index and Constraints Updates

Dartonic now supports an enhanced approach for defining indexes and constraints using the `.on` method. This method is available in classes like `IndexConstraint`, `UniqueConstraint`, and `PrimaryKeyConstraint`. Here’s how they work:

- **Index Example:**  
  Define an index for a table column by calling the `index` helper and using `.on()`.  
  **SQL Generated:**

  ```sql
  CREATE INDEX IF NOT EXISTS name_idx ON (name);
  ```

  **Example:**

  ```dart
  final usersTable = sqliteTable(
    'users',
    {
      'id': integer().primaryKey(autoIncrement: true),
      'name': text().notNull(),
      'email': text().notNull(),
      'age': integer(),
      'created_at': datetime().defaultNow(),
    },
    () => [
      index('name_idx').on(['name']),
    ],
  );
  ```

- **Constraint Example:**  
  Define a unique constraint using `unique` with `.on()` to enforce uniqueness over the specified columns.  
  **SQL Generated:**

  ```sql
  CONSTRAINT unique_book UNIQUE (title, author)
  ```

  **Example:**

  ```dart
  final booksTable = sqliteTable(
    'books',
    {
      'id': integer().primaryKey(autoIncrement: true),
      'title': text().notNull(),
      'author': text().notNull(),
      'published_year': integer(),
    },
    () => [
      unique('unique_book').on(['title', 'author']),
    ],
  );
  ```

- **PrimaryKey Example:**  
  The primary key constraint can be defined inline with the column definition or as a table-level constraint. When defined as a table constraint, the SQL is generated as follows:  
  **SQL Generated:**
  ```sql
  CONSTRAINT pk_users PRIMARY KEY (id)
  ```
  **Example:**
  ```dart
  final usersTable = sqliteTable(
    'users',
    {
      'id': integer(),
      'name': text().notNull(),
      'email': text().notNull(),
      'age': integer(),
      'created_at': datetime().defaultNow(),
    },
    () => [
      primaryKey(columns: ['id']),
    ],
  );
  ```

💡 **Note:** Depending on the database (SQLite, MySQL, etc.), Dartonic adapts the generated SQL appropriately. For example, on MySQL, `"AUTOINCREMENT"` is converted to `"AUTO_INCREMENT"`.

<br/>

---

<br/>

## Working with Relationships

Dartonic allows you to define relationships between tables. This makes it easier to perform related queries using JOINs. Relationships are defined through helper methods (for example, a `relations` function) which let you map the associations.

Here’s an example of defining one-to-one and one-to-many relationships:

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

// Now initialize Dartonic with the main tables and relationship meta-information.
final dartonic = Dartonic("sqlite://database.db", [
  usersTable,
  profileTable,
  postsTable,
  usersRelations,
  postsRelations,
]);
```

Once the relationships are defined, you can perform JOIN queries with ease:

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
```

**Generated SQL Example for JOIN:**

```sql
SELECT users.name AS userName, users.email AS userEmail, profile_info.bio AS bio
FROM users
INNER JOIN profile_info ON users.id = profile_info.user_id;
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
  ```

  **Generated SQL:**

  ```sql
  SELECT * FROM users;
  ```

- **SELECT specific columns using a map:**

  Here, the key represents the alias and the value represents the actual column.

  ```dart
  final result = await db.select({
    'fieldId': 'users.id',
    'fieldName': 'users.name',
  }).from('users');
  ```

  **Generated SQL:**

  ```sql
  SELECT users.id AS fieldId, users.name AS fieldName FROM users;
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
```

**Generated SQL Example:**

```sql
SELECT users.name AS userName, orders.total AS orderTotal
FROM users
INNER JOIN orders ON users.id = orders.user_id
WHERE orders.total > ?
ORDER BY users.name ASC
LIMIT 10 OFFSET 0;
```

<br/>

---

<br/>

## Supported Methods & Examples

Below are some examples demonstrating all available methods within Dartonic's query builder.

<br/>

### SELECT

```dart
final users = await db
    .select({
      'name': 'users.fullname',
      'age': 'users.birthday'
    })
    .from('users');
```

<br/>

### INSERT

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

// Insert and return only id
final insertedPartial = await db
    .insert('users')
    .values({
      'name': "Partial Dan",
      'age': 30
    })
    .returning(insertedId: 'users.id');

print("Inserted with partial RETURNING (only id):");
```

**Generated SQL Example for Insertion:**

```sql
-- Insertion without RETURNING
INSERT INTO users (name, age) VALUES (?, ?);

-- Insertion with RETURNING (if supported)
INSERT INTO users (name, age) VALUES (?, ?) RETURNING id;
```

<br/>

### UPDATE

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
```

**Generated SQL Example for Update:**

```sql
-- Update without RETURNING
UPDATE users SET name = ?, age = ? WHERE users.id = ?;

-- Update with RETURNING (if supported)
UPDATE users SET name = ?, age = ? WHERE users.id = ? RETURNING *;
```

<br/>

### DELETE

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
```

**Generated SQL Example for Delete:**

```sql
-- Delete without RETURNING
DELETE FROM users WHERE users.id = ?;

-- Delete with RETURNING (if supported)
DELETE FROM users WHERE users.id = ? RETURNING *;
```

<br/>

### Join Queries

```dart
// INNER JOIN example: users and orders
final joinQuery = await db
    .select({
      'userName': 'users.name',
      'orderTotal': 'orders.total'
    })
    .from('users')
    .innerJoin('orders', eq("users.id", "orders.user_id"))
    .where(gt("orders.total", 100));

print("SQL INNER JOIN with filter:");
```

**Generated SQL Example for INNER JOIN:**

```sql
SELECT users.name AS userName, orders.total AS orderTotal
FROM users
INNER JOIN orders ON users.id = orders.user_id
WHERE orders.total > ?;
```

<br/>

### Filter Conditions

```dart
// Equality filter (eq)
final eqQuery = await db.select().from("users").where(eq("users.age", 30));

// Greater-than filter (gt)
final gtQuery = await db.select().from("users").where(gt("users.age", 25));

// In array filter
final inArrayQuery = await db.select().from("users").where(inArray("users.age", [25, 35]));

// Between filter
final betweenQuery = await db.select().from("users").where(between("users.age", 26, 34));

// Composite filter with AND
final andQuery = await db.select().from("users").where(
  and([gt("users.age", 25), lt("users.age", 35)])
);

// Composite filter with OR
final orQuery = db.select().from("users").where(
  or([lt("users.age", 25), gt("users.age", 35)])
);
```

**Generated SQL Examples for Filters:**

```sql
-- Equality Filter:
SELECT * FROM users WHERE users.age = ?;

-- Greater-than Filter:
SELECT * FROM users WHERE users.age > ?;

-- In Array Filter:
SELECT * FROM users WHERE users.age IN (?, ?);

-- Between Filter:
SELECT * FROM users WHERE users.age BETWEEN ? AND ?;

-- Composite AND Filter:
SELECT * FROM users WHERE (users.age > ? AND users.age < ?);

-- Composite OR Filter:
SELECT * FROM users WHERE (users.age < ? OR users.age > ?);
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

Contributions are very welcome! If you find bugs, have suggestions, or want to contribute new features, please submit an [issue](https://github.com/evandersondev/dartonic/issues) or a pull request.

---

## License

🍷 Dartonic is released under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

Made with ❤️ for Dart/Flutter developers! 🎯
