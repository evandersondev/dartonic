import 'package:relations_blog/relations_blog.dart';

Future<void> main() async {
  final app = await bootstrap();

  app.listen(3000);
}
