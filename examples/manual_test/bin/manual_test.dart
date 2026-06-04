import 'package:manual_test/app.dart';

void main() async {
  final app = await createApp();

  app.listen(8080);
}
