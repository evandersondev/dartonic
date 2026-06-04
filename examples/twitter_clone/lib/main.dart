import 'db/database.dart';
import 'repositories/post_repository.dart';
import 'repositories/user_repository.dart';

void main() async {
  final db = await openDatabase();

  final userRepo = UserRepository(db);
  final postRepo = PostRepository(db);

  // ── Seed users ──────────────────────────────────────────────────────────
  await userRepo.create(
    username: 'alice',
    displayName: 'Alice Smith',
    bio: 'Dart developer. Building things with Dartonic.',
  );
  await userRepo.create(
    username: 'bob',
    displayName: 'Bob Jones',
    bio: 'Flutter enthusiast.',
  );
  await userRepo.create(
    username: 'carol',
    displayName: 'Carol Wu',
  );

  final alice = await userRepo.findByUsername('alice');
  final bob   = await userRepo.findByUsername('bob');
  final carol = await userRepo.findByUsername('carol');

  // ── Seed posts ───────────────────────────────────────────────────────────
  await postRepo.create(
    userId: alice!.id,
    content: 'Just shipped Dartonic — type-safe SQL for Dart with zero codegen 🚀',
  );
  await postRepo.create(
    userId: alice.id,
    content: 'Joins, conditions, and migrations. All in one package.',
  );
  await postRepo.create(
    userId: bob!.id,
    content: 'Finally a Dart ORM that feels like Drizzle. Love it.',
  );
  await postRepo.create(
    userId: carol!.id,
    content: 'Testing Dartonic with PostgreSQL next — fingers crossed!',
  );

  // ── Timeline (all posts with author info) ────────────────────────────────
  final feed = await postRepo.timeline();
  _header('Timeline (${feed.length} posts)');
  for (final p in feed) {
    print('  $p');
  }

  // ── Alice's posts ────────────────────────────────────────────────────────
  final alicePosts = await postRepo.findByUsername('alice');
  _header("@alice's posts (${alicePosts.length})");
  for (final p in alicePosts) {
    print('  $p');
  }

  // ── Users + their posts in 2 SQL queries (no N+1) ────────────────────────
  final usersWithPosts = await userRepo.findAllWithPosts();
  _header('Users with their posts (preloaded)');
  for (final entry in usersWithPosts) {
    print('  ${entry.parent} — ${entry.children.length} post(s)');
    for (final p in entry.children) {
      print('    · ${p.content}');
    }
  }

  // ── All users ────────────────────────────────────────────────────────────
  final allUsers = await userRepo.findAll();
  _header('All users (${allUsers.length})');
  for (final u in allUsers) {
    print('  $u');
  }

  // ── Update + re-fetch ────────────────────────────────────────────────────
  await userRepo.update(carol.id, bio: 'PostgreSQL results: 🎉 works great!');
  final updated = await userRepo.findByUsername('carol');
  _header('Updated carol');
  print('  $updated');
}

void _header(String title) {
  print('\n── $title ${'─' * (42 - title.length)}');
}
